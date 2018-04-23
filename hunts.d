module hunts;

import std.stdio;
import std.regexp;
import std.file;
import std.date;
import std.string:atoi;
import std.string:join;

import alogprocessor;

class Hunts : public ALogProcessor
{
protected:
	RegExp rekill, restartlog, reendlog;
	int[char[]] Kills;
	char[][][char[]] KillTimes;
public:
	int OnlineTime;
public:
	void Create(char[] Charname)
	{
		rekill = RegExp("^" ~ reTimestamp ~ "Du hast( geholfen,)? ein(en?)? (.+) (geschlachtet|erlegt|getötet|bezwungen|zu schlachten|zu erlegen|zu töten|zu bezwingen).$");
		restartlog = RegExp("^" ~ parent.reTimestamp ~ " Willkommen (bei Arindal|zurück), " ~ Charname ~ "!$");
		reendlog = RegExp("^" ~ parent.reTimestamp ~ r" \*\*\* Wir sind nicht mehr mit dem Arindal-Spielserver verbunden. \*\*\*$");
	}
	void ProcessLine(char[] line)
	{
		// online time
		static bool isOnline=false;
		d_time StartTime;
		if (!isOnline)
		{
			auto m = restartlog.match(line);
			if (m.length)
			{
				StartTime = parent.ArindalTsToDate(m);
				isOnline = true;
			}
		}else
		{
			auto m = reendlog.match(line);
			if (m.length)
			{
				OnlineTime += parent.ArindalTsToDate(m) - StartTime;
				isOnline = false;
			}
		}
		
		// kills
		auto m = rekill.match(line);
		if (m.length)
		{
			if (!(m[5] in Kills)) Kills[m[5]] = 0;
			Kills[m[5]]++;
		}
	}
	char[] GetName()
	{
		return "hunts (experimental)";
	}
	
	void PrintStats()
	{
		writefln("\nHunts\n-----");
		int restOnlineTime = OnlineTime / 1000;
		const int secondsInDay = (24*60*60);
		const int secondsInHour = (60*60);
		const int secondsInMinute = 60;
		int totalhours = restOnlineTime/secondsInHour;
		int days = restOnlineTime/secondsInDay;
		restOnlineTime -= days*secondsInDay;
		int hours = restOnlineTime/secondsInHour;
		restOnlineTime -= hours*secondsInHour;
		int minutes = restOnlineTime/secondsInMinute;
		restOnlineTime -= minutes*secondsInMinute;
		
		writefln("Total Online Time %dd %dh %dm %ds",
			days, hours, minutes, restOnlineTime);
		writefln("Kills per hour:");

		/*foreach (monster, kills;Kills)
		{
			writefln("%s: %2s", monster, cast(float)kills/totalhours);
		}*/
	}
}