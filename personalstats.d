module personalstats;

import std.stdio;
import std.regexp;
import std.file;
import std.string:atoi;
import std.string:join;

import alogprocessor;
import arankcounter;

class PersonalStats : public ALogProcessor
{
protected:
	RegExp remiscinfos, retitle;
	char[] Charname;
	char[] Race;
	char[] Sex;
	char[] Profession;
	char[] Title;
public:
	this()
	{

	}
	void Create(AtlpCfg cfg)
	{
		this.Charname = cfg.Charname;
		remiscinfos = RegExp("^" ~ reTimestamp ~ "Du bist eine? ([^,]+), bist ([^,]+), bist eine? ([^,]+),(.*)$");
		retitle = RegExp("^" ~ reTimestamp ~ "(" ~ ARankCounter.retrainers ~ ") sagt, \"Hail, ([a-zA-Z ]+) " ~ Charname ~ "\\. (.*)\"$");
		//reprofession
	}
	void ProcessLine(char[] line)
	{
		auto m = retitle.match(line);
		if (m.length)
		{
			if (Title != m[4]) Title = m[4];
		}
		if (Profession == "")
		{
			m = remiscinfos.match(line);
			if (m.length)
			{
				Race = m[3];
				Sex = m[4];
				Profession = m[5];
			}
		}		
	}
	char[] GetName()
	{
		return "personal stats";
	}
	
	void PrintStats()
	{
		writefln("\nPersonal Stats\n--------------");
		writefln("Name: %s", Charname);
		writefln("Race: %s", Race);
		writefln("Sex: %s", Sex);
		writefln("Profession: %s", Profession);
		writefln("Title: %s", Title);
	}
}