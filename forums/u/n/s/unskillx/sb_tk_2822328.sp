#include <sourcemod>
#define PLUGIN_VERSION  "0.0.1"

public OnPluginStart(){
	int flags=GetCommandFlags("sb_takecontrol");
	SetCommandFlags("sb_takecontrol", flags & ~FCVAR_CHEAT);
}