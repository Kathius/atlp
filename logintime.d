module logintime;

import std.stdio;
import std.regexp;
import std.file;
import std.date;
import std.string:atoi;
import std.string:join;

import alogprocessor;

class LoginTime : public ALogProcessor
{
protected:
	bool bStart, bEnd;
	d_time StartTime, EndTime;
	char[] lastline;
	RegExp ExtractTime;
	long OnlineTime, LongestLog;
public:
	this()
	{
		bStart = false;
		bEnd = false;
		ExtractTime = RegExp("^" ~ parent.reTimestamp ~ ".+$");
		OnlineTime = 0;
		LongestLog = 0;
		StartTime = EndTime = 0;
	}
	void ProcessLine(char[] line)
	{
		if (bStart)
		{
			auto m = ExtractTime.match(line);
			if (m.length)
			{
				StartTime = parent.ArindalTsToDate(m);
				bStart = false;
			}
		}
		lastline = line;
	}
	void OnOpenLogFile()
	{
		bStart = true;
	}
	void OnCloseLogFile()
	{
		auto m = ExtractTime.match(lastline);
		if (m.length)
		{
			EndTime = parent.ArindalTsToDate(m);
		}
		LongestLog = LongestLog >= EndTime-StartTime ? LongestLog : EndTime-StartTime;
		OnlineTime += (EndTime-StartTime);
	}
	char[] GetName()
	{
		return "login time stats";
	}
	
	void PrintStats()
	{
		writefln("\nLogin Time Stats\n---------");
		writefln("Total Online Time %s", GetTimeString(OnlineTime));
		writefln("Longest continuous Online Time %s", GetTimeString(LongestLog));

	}
	
	char[] GetTimeString(long msecs)
	{
		long restOnlineTime = msecs / 1000;
		const int secondsInDay = (24*60*60);
		const int secondsInHour = (60*60);
		const int secondsInMinute = 60;
		auto totalhours = restOnlineTime/secondsInHour;
		auto days = restOnlineTime/secondsInDay;
		restOnlineTime -= days*secondsInDay;
		auto hours = restOnlineTime/secondsInHour;
		restOnlineTime -= hours*secondsInHour;
		auto minutes = restOnlineTime/secondsInMinute;
		restOnlineTime -= minutes*secondsInMinute;

		return std.string.format("%dd %dh %dm %ds", days, hours, minutes, restOnlineTime);
	}
}