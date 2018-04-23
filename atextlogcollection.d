module atextlogcollection;

import std.stdio;
import std.file;
import std.regexp;
import std.date;
import std.stream;
import std.string;

public struct AtlpCfg
{
	char[] Path;
	char[] Charname;
};


public import alogprocessor;
public import arankcounter;
public import killcounter;
public import milestones;
public import personalstats;
public import fallentos;
public import hunts;
public import logintime;

version (Win32)
{
private import std.c.windows.windows;
private import std.utf;
private import std.windows.syserror;
private import std.windows.charset;
private import std.date;

int useWfuncs = 1;

static this()
{
    // Win 95, 98, ME do not implement the W functions
    useWfuncs = (GetVersion() < 0x80000000);
}
}


class ATextlogCollection
{
protected:
	char[] ArindalRootDir;
	char[] TextlogDir;
	char[] Character;
	AtlpCfg cfg;
	ALogProcessor[] Procs;
public:
	const char[] reTimestamp = "((\\d\\d?)/(\\d\\d?)/(\\d\\d) (\\d\\d?):(\\d\\d):(\\d\\d)(a|p))";
	RegExp retime;
public:
	this(AtlpCfg cfg)
	{
		this.cfg = cfg;
		ArindalRootDir = cfg.Path;
		Character = cfg.Charname;
		TextlogDir = ArindalRootDir ~ "/data/Text Logs/" ~ Character;
		retime = RegExp("^" ~ reTimestamp ~ ".*$");
	}
	void AttachLoglineProcessor(ALogProcessor proc)
	{
		Procs ~= proc;
		proc.parent = this;
		proc.Create(cfg);
	}
	void ProcessFiles()
	{
		//writefln(TextlogDir);
		auto files = std.file.listdir(TextlogDir, RegExp("CL Log"));
		files.sort;
		//writefln("Dateien: %d", files.length);
		foreach (file; files)
		{
			try
			{
				auto content = cast(char[])read(file);
				auto lines = std.regexp.split(content, "\r?\n|\r");
				foreach (lp; Procs) lp.OnOpenLogFile();
				foreach(line;lines)
				{
					foreach (lp; Procs) lp.ProcessLine(line);
				}
				foreach (lp; Procs) lp.OnCloseLogFile();
			}catch (Exception e)
			{
				continue;
			}
		}
	}
	d_time ArindalTsToDate(char[][] m)
	{
		char[] strdate = std.string.format("20%s-%s-%s %s:%s:%s%sm",
			m[4], m[2], m[3],
			m[5], m[6], m[7], m[8]);
		return std.date.parse(strdate);
	}
	void ProcessFiles(d_time start, d_time end)
	{
		auto files = std.file.listdir(TextlogDir, RegExp("CL Log"));
		files.sort;
		//writefln(TextlogDir);
		//writefln("Dateien: %d", files.length);
		foreach (file; files)
		{
			auto filedate = 
				RegExp(r"^(.*)CL Log (\d\d\d\d)-(\d\d)-(\d\d) (\d\d)\.(\d\d)\.(\d\d)\.txt$").replace(file,
				"$2-$3-$4 $5:$6:$7");
			// If the format is wrong, skip this file
			if (filedate == file) continue;
			//writefln(filedate);
			auto filetimestamp = std.date.parse(filedate);
			
			int diff = 2 * 24 * 60 * 60 * 1000; // 2 days
			// if the first line is more than 2 days before our startdate
			// it is very unlikely that ANY timestamp is within range
			// so skip this file
			if ((filetimestamp+diff) < start)
			{
				continue;
			}
			// if the first line is after our enddate, the whole file is
			// obviously too new, so skip it
			if (filetimestamp > end)
			{
				continue;
			}
			
			try
			{
				//auto content = cast(char[])read(file);
				auto content = cast(char[])ReadLogFile(file);
				auto lines = std.regexp.split(content, "\\r\\n");
				
				// if the first line is not more than 2 days before the end date
				// it is possible that a later timestamp in that file is already
				// behind the end date
				// if the first line is before our start date, it is possible that
				// a later timestamp in that file is still after the start date
				// in both cases we have to check every timestamp in that file
				if (filetimestamp+diff > end || filetimestamp < start)
				{
					// find out the first non-empty line
					int startline=0;
					while (lines[startline]=="") startline++;
					
					// if there are no timestamps, we cannot use this file
					auto m = retime.match(lines[startline]);
					if (m.length == 0)
					{
						continue;
					}
					
					for (int i=startline;i<lines.length;i++)
					{
						auto line = lines[i];
						m = retime.match(line);
						if (m.length == 0) continue; 
						auto linetime = ArindalTsToDate(m);
						if (start <= linetime && linetime <= end)
						{
							foreach (lp; Procs) lp.ProcessLine(line);
						}
					}
				}else // file doesn't have to be checked
				{
					foreach (lp; Procs) lp.OnOpenLogFile();
					foreach (line;lines)
					{
						foreach (lp; Procs) lp.ProcessLine(line);
					}
					foreach (lp; Procs) lp.OnCloseLogFile();
				}
			}catch (Exception e)
			{
				writefln(e.toString());
				continue;
			}
		}
	}
	void[] ReadLogFile(char[] name)
	{
		version (Win32)
		{
	    DWORD numread;
	    HANDLE h;

	    if (useWfuncs)
	    {
		wchar* namez = std.utf.toUTF16z(name);
		h = CreateFileW(namez,GENERIC_READ,FILE_SHARE_READ | FILE_SHARE_WRITE,null,OPEN_EXISTING,
		    FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN,cast(HANDLE)null);
	    }
	    else
	    {
		char* namez = std.windows.charset.toMBSz(name);
		h = CreateFileA(namez,GENERIC_READ,FILE_SHARE_READ | FILE_SHARE_WRITE,null,OPEN_EXISTING,
		    FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN,cast(HANDLE)null);
	    }

	    if (h == INVALID_HANDLE_VALUE)
		goto err1;

	    auto size = GetFileSize(h, null);
	    if (size == INVALID_FILE_SIZE)
		goto err2;

	    auto buf = std.gc.malloc(size);
	    if (buf)
		std.gc.hasNoPointers(buf.ptr);

	    if (ReadFile(h,buf.ptr,size,&numread,null) != 1)
		goto err2;

	    if (numread != size)
		goto err2;

	    if (!CloseHandle(h))
		goto err;

	    return buf[0 .. size];

	err2:
	    CloseHandle(h);
	err:
	    delete buf;
	err1:
	    throw new FileException(name, GetLastError());
		}else
		{
			return read(name);
		}
	}
	
};