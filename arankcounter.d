module arankcounter;

import std.stdio;
import std.regexp;
import std.file;
import std.string:atoi;
import std.string:join;

import alogprocessor;

class ARankCounter : ALogProcessor
{
public:
	static RegExp resysmsg, retrnmsg;
	static char[] retrainers;
protected:
	char[][char[]] SysMsgMap;
	int[char[]] TrnMsgMap;
	int[char[]] Ranks;
	char[] Charname;
	bool simple=false;
public:
	this(bool Simple=false)
	{
		simple = Simple;
	}
	void Create(AtlpCfg cfg)
	{
		Charname = cfg.Charname;
		// Trainernachrichten laden
		auto file = (cast(char[])read("trainers.cfg")).split("\r?\n|\r");
		int i;
		for (i=0;i<file.length && file[i] != "";i++)
		{
			auto trn = file[i].split("\t");
			SysMsgMap[trn[1]] = trn[0];
			Ranks[trn[0]] = 0;
		}
		for (++i;i<file.length && file[i] != "";i++)
		{
			auto trn = file[i].split("\t");
			TrnMsgMap[trn[1]] = cast(int)atoi(trn[0]);
		}
		// Die Regexps
		resysmsg = RegExp("^" ~ reTimestamp ~ "•((Du|Deine?) .+)$");
		retrainers = join(Ranks.keys, "|");
		retrnmsg = RegExp("^" ~ reTimestamp ~ "(" ~ join(Ranks.keys, "|") ~ ") sagt, \"Hail,[a-zA-Z ]+" ~ Charname ~ "\\. (.*)\"$");
	}
	void ProcessLine(char[] content)
	{
		foreach(m; resysmsg.search(content))
		{
			CheckGameMessage(m.match(3));
			return;
		}
		if (!simple)
		{
			foreach(m; retrnmsg.search(content))
			{
				CheckTrainerMessage(m.match(3), m.match(4));
				return;
			}
		}
	}
	void CheckGameMessage(char[] msg)
	{
		if ((msg in SysMsgMap) != null)
		{
			Ranks[SysMsgMap[msg]]++;
		}		
	}
	void CheckTrainerMessage(char[] trainer, char[] msg)
	{
		if ((msg in TrnMsgMap) != null)
		{
			Ranks[trainer] = (Ranks[trainer] > TrnMsgMap[msg]) ? Ranks[trainer] : TrnMsgMap[msg];
		}		
	}
	void PrintStats()
	{
		if (simple)	writefln("\nRanks (simple)\n--------------");
		else writefln("\nRanks\n-----");
		foreach (trn, rnk; Ranks)
		{
			if (rnk > 0) writefln("%s: %d", trn, rnk);
		}
	}
	char[] GetName()
	{
		return simple ? "rank counter simple" : "rank counter extended (default)";  
	}
	
	char[] toString()
	{
		return "ARankcounter";
	}
	
};