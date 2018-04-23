import std.stdio;
import std.file;
import std.regexp;
import std.date;

import atextlogcollection;

class LogProcessorEntry
{
public:
	ALogProcessor	prc;
	char			letter;
	bool 			activated;
	this(ALogProcessor pr, char l, bool a=false)
	{
		prc=pr;
		letter=l;
		activated=a;
	}	
};

int main(char[][] argv)
{
	writefln("Arindal Text Log Processor");
	
	bool SaveSettings=false;
	AtlpCfg cfg;
	LogProcessorEntry[] prcs;
	prcs ~= new LogProcessorEntry(new ARankCounter(), 'R', true);
	prcs ~= new LogProcessorEntry(new ARankCounter(true), 'r');
	prcs ~= new LogProcessorEntry(new KillCounter(), 'K');
	//prcs ~= new LogProcessorEntry(new KillTimes(), 'k');
	prcs ~= new LogProcessorEntry(new Milestones(), 'M');
	prcs ~= new LogProcessorEntry(new PersonalStats(), 'P');
	prcs ~= new LogProcessorEntry(new FallenTos(), 'F');
	prcs ~= new LogProcessorEntry(new Hunts(), 'H');
	
	char[] Starttime;
	char[] Endtime;
	
	try
	{
		for (int i=1;i<argv.length;i++)
		{
			switch (argv[i])
			{
			case "-p":
				if (i == argv.length-1)
				{
					PrintUsage(prcs);
					return 0;
				}
				cfg.Path = argv[i+1];
				i++;
				break;
			case "-c":
				if (i == argv.length-1)
				{
					PrintUsage(prcs);
					return 0;
				}
				cfg.Charname = argv[i+1];
				i++;
				break;
			case "-dS":
				if (i == argv.length-1)
				{
					PrintUsage(prcs);
					return 0;
				}
				Starttime = argv[i+1];
				i++;
				break;
			case "-dE":
				if (i == argv.length-1)
				{
					PrintUsage(prcs);
					return 0;
				}
				Endtime = argv[i+1];
				i++;
				break;
			case "-dD":
				if (i == argv.length-1)
				{
					PrintUsage(prcs);
					return 0;
				}
				Starttime = Endtime = argv[i+1];
				i++;
				break;
			default:
				auto m = search(argv[i], "^-m([a-zA-Z]+)$");
				if (m)
				{
					foreach (lp; prcs) lp.activated = false;
					param: foreach (t; m.match(1))
					{
						foreach (lp; prcs) if (lp.letter == t)
						{
							lp.activated = true;
							continue param;
						}
						writefln("Unknown module: %s", t);
						PrintUsage(prcs);
						return 0;
					}
					continue;
				}				
				writefln("Unrecognized parameter: %s", argv[i]);
				PrintUsage(prcs);
				return 0;
			}
		}
	}catch (Exception e)
	{
		writefln(e.toString());
	}
	
	if (cfg.Path == "" || cfg.Charname == "")
	{
		PrintUsage(prcs);
		return 0;
	}

	try
	{
		auto tlc = new ATextlogCollection(cfg);
		foreach (lp; prcs) if (lp.activated)
		{
			tlc.AttachLoglineProcessor(lp.prc);
		}
		if (Starttime == "" && Endtime == "")
		{
			tlc.ProcessFiles();
		}else
		{
			if (Starttime == "") Starttime = "2000-01-01 00:00:00";
			if (Endtime == "") Endtime = "2020-01-01 23:59:59";
			// normalize dates
			Starttime = MakeStandardDate(Starttime, "0:0:0");
			Endtime = MakeStandardDate(Endtime, "23:59:59");
			
			tlc.ProcessFiles(std.date.parse(Starttime), std.date.parse(Endtime));
		}
		foreach (lp; prcs) if (lp.activated) lp.prc.PrintStats();
	}catch (Exception e)
	{
		writefln(e.toString());
	}
		
	return 0;
}

char[] MakeStandardDate(char[] indate, char[] opttime)
{
	char[] outdate;
	char[] regermandate = r"(\d\d?)\.(\d\d?)\.((\d\d)?\d\d)";
	char[] restddate = r"((\d\d)?(\d\d))-(\d\d?)-(\d\d?)";
	char[] retime = r"(\d\d?):(\d\d):(\d\d)";
	char[] rechkvalid = "^ *" ~ restddate ~ " *( " ~ retime ~ " *)?$";
	// convert german date
	outdate = RegExp("^ *" ~ regermandate).replace(indate, "$3-$2-$1");
	// check for valid date
	auto tm = RegExp(rechkvalid).match(outdate);
	if (tm.length == 0)
	{
		throw new Exception("invalid date");
	}
	outdate = "20"~tm[3]~"-"~tm[4]~"-"~tm[5];
	if (tm[6] != "") outdate ~=" "~tm[7]~":"~tm[8];
	else outdate ~= " "~opttime;
	return outdate;
}

void PrintUsage(LogProcessorEntry[] prcs)
{
	char[] modules;
	foreach (lp; prcs) modules ~= lp.letter;

	writefln("Usage: atlp [-m<%s>] -p <path> -c <char> [additional options]\n", modules);
	writefln("  -p <path>  Arindal base path");
	writefln("  -c <char>  name of character");
	writefln("  -dS <date> start time");
	writefln("  -dE <date> end time");
	writefln("  -dD <date> exact day");
	writefln("  -m<%s>  use following modules", modules);

	foreach (lp; prcs) writefln("    %s        %s", lp.letter, lp.prc.GetName());

	writefln("\nExamples:");
	writefln("  show ranks:             atlp -p \"c:/arindal\" -c Kathius");
	writefln("  show kills:             atlp -mK -p \"c:/arindal\" -c Kathius");
	writefln("  show ranks and kills:   atlp -mRK -p \"c:/arindal\" -c Kathius");
	writefln("  show kills in 2007:");
	writefln("    atlp -mK -p \"c:/arindal\" -c Kathius -dS 2007-01-01");
	writefln("  show kills and ranks on 7th Jan 2007:");
	writefln("    atlp -mKr -p \"c:/arindal\" -c Kathius -dD 2007-01-07");
}