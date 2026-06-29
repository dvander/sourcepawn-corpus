#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Motd",
	author = "SAMURAI",
	description = "",
	version = "0.1",
	url = ""
}

new Handle:cvar_adv;

public OnPluginStart()
{
	RegConsoleCmd("say",fnHookSay);
	
	cvar_adv = CreateConVar("motd_Advertise","60");
	
	
	CreateTimer(20.0,fnAdvertise);
}

public Action:fnHookSay(id,args)
{
	decl String:SayText[191];
	GetCmdArgString(SayText, sizeof(SayText));
	
	StripQuotes(SayText);
	
	if(StrEqual(SayText,"music"))
	{
		ShowMOTDPanel(id,"music.txt","Show Music Motd",MOTDPANEL_TYPE_INDEX);
		
		new String:name[32];
		GetClientName(id,name,sizeof(name));
		
		PrintToChatAll("\x01\x04dont shoot \x03%s \x04because he or she is reading the music page!",name)
	}
}

public Action:fnAdvertise(Handle:timer)
{
	PrintToChatAll("\x01\x04Say \x03music \x04to turn on, or off music.");
	
	CreateTimer(GetConVarFloat(cvar_adv),fnAdvertise);
}