module killcounter;

import std.stdio;
import std.regexp;
import std.file;
import std.string:atoi;
import std.string:join;

import alogprocessor;

class KillCounter : public ALogProcessor
{
protected:
	RegExp rekill;
	int[][char[]] Kills;
	char[][][char[]] KillTimes;
public:
	this()
	{
		rekill = RegExp("^" ~ reTimestamp ~ "Du hast( geholfen,)? ein(en?)? (.+) (geschlachtet|erlegt|getötet|bezwungen|zu schlachten|zu erlegen|zu töten|zu bezwingen).$");
	}
	void ProcessLine(char[] line)
	{
		foreach (m; rekill.search(line))
		{
			if (!(m.match(5) in Kills))
			{
				Kills[m.match(5)] = [0,0,0,0,0,0,0,0];
				KillTimes[m.match(5)] = ["", "", "", ""];
			}
			switch (m.match(6))
			{
			case "geschlachtet":
				Kills[m.match(5)][0]++;
				if (KillTimes[m.match(5)][0] == "") KillTimes[m.match(5)][0] = m.match(1);
				break;
			case "erlegt":
				Kills[m.match(5)][1]++;
				if (KillTimes[m.match(5)][0] == "") KillTimes[m.match(5)][1] = m.match(1);
				break;
			case "getötet":
				Kills[m.match(5)][2]++;
				if (KillTimes[m.match(5)][0] == "") KillTimes[m.match(5)][2] = m.match(1);
				break;
			case "bezwungen":
				Kills[m.match(5)][3]++;
				if (KillTimes[m.match(5)][0] == "") KillTimes[m.match(5)][3] = m.match(1);
				break;
			case "zu schlachten":
				Kills[m.match(5)][4]++;
				if (KillTimes[m.match(5)][0] == "") KillTimes[m.match(5)][0] = m.match(1);
				break;
			case "zu erlegen":
				Kills[m.match(5)][5]++;
				if (KillTimes[m.match(5)][0] == "") KillTimes[m.match(5)][1] = m.match(1);
				break;
			case "zu töten":
				Kills[m.match(5)][6]++;
				if (KillTimes[m.match(5)][0] == "") KillTimes[m.match(5)][2] = m.match(1);
				break;
			case "zu bezwingen":
				Kills[m.match(5)][7]++;
				if (KillTimes[m.match(5)][0] == "") KillTimes[m.match(5)][3] = m.match(1);
				break;
			default:
			}
		}		
	}
	char[] GetName()
	{
		return "kill counter";
	}
	
	void PrintStats()
	{
		writefln("\nKills\n-----");
		foreach (Monster, arKills; Kills)
		{
			writefln("%s: %d, %d, %d, %d, %d, %d, %d, %d", 
				Monster,
				arKills[0], arKills[1], arKills[2], arKills[3], 
				arKills[4], arKills[5], arKills[6], arKills[7]);
		}
	}
	void PrintKilltimes()
	{
		writefln("\nFirst Kills\n-----------");
		foreach (Monster, arKills; KillTimes)
		{
			writefln("%s: %s, %s, %s, %s", 
				Monster,
				arKills[0], arKills[1], arKills[2], arKills[3]);
		}
	}
}