module fallentos;

import std.stdio;
import std.regexp;
import std.file;
import std.string:atoi;
import std.string:join;

import alogprocessor;

class FallenTos : public ALogProcessor
{
protected:
	RegExp refallen;
	int[char[]] FallenTos;
public:
	this()
	{
		refallen = RegExp("^" ~ reTimestamp ~ "Du bist durch ein(en?)? (.+) gefallen.$");
	}
	void ProcessLine(char[] line)
	{
		foreach (m; refallen.search(line))
		{
			if (!(m.match(4) in FallenTos))
			{
				FallenTos[m.match(4)] = 0;
			}
			FallenTos[m.match(4)]++;
		}		
	}
	char[] GetName()
	{
		return "fallen";
	}
	
	void PrintFallenTos()
	{
		writefln("\nFallen To\n---------");
		foreach (Monster, Number; FallenTos)
		{
			writefln("%s: %d", Monster, Number);
		}
	}
}