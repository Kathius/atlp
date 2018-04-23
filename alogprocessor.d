module alogprocessor;

public import atextlogcollection;

class ALogProcessor
{
protected:
	const char[] reTimestamp = "(\\d\\d?/\\d\\d?/\\d\\d \\d\\d?:\\d\\d:\\d\\d(a|p) )?";
	AtlpCfg cfg;
public:
	ATextlogCollection parent;
public:
	int iTest;
	this()
	{
	}
	void OnOpenLogFile()
	{
	}
	void OnCloseLogFile()
	{
	}
	void ProcessLine(char[] content)
	{
	}
	void Create(AtlpCfg cfg)
	{
		this.cfg = cfg;
	}
	char[] toString()
	{
		return "ALogProcessor";
	}
	char[] GetName()
	{
		return "<experimental>";
	}
	void PrintStats()
	{
	}
};