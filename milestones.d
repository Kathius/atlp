module milestones;

import std.stdio;
import std.regexp;
import std.file;
import std.string:atoi;
import std.string:join;

import alogprocessor;
import arankcounter;

class Milestones : public ALogProcessor
{
protected:
	RegExp retitle;
	char[][char[]] TitleTimes;
	char[] Charname;
public:
	this()
	{
	}
	void Create(AtlpCfg cfg)
	{
		Charname = cfg.Charname;
		retitle = RegExp("^" ~ reTimestamp ~ "(" ~ ARankCounter.retrainers ~ ") sagt, \"Hail, ([a-zA-Z ]+) " ~ Charname ~ "\\. (.*)\"$");
	}
	void ProcessLine(char[] content)
	{
		foreach(m; retitle.search(content))
		{
			if (!(m.match(4) in TitleTimes)) TitleTimes[m.match(4)] = m.match(1);
			return;
		}
	}
	char[] GetName()
	{
		return "milestones";
	}

	void PrintStats()
	{
		writefln("\nMilestones\n----------");
		foreach (title, time; TitleTimes)
		{
			writefln("%s: %s", title, time);
		} 
	}
};