#include <sourcemod>

#define BASE_CMD "test"
#include <basecmd>

public OnPluginStart()
{
	BaseCmd_Init();
	LoadTranslations("pluginname.basecmd.phrases");
}