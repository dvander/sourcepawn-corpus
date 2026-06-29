#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "Jumpscare",
	author = "Danian",
	description = "Scare the crap out of people by jumpscaring them.",
	version = "1.0",
	url = "http://danian.website"
}

public OnPluginStart()
{
	RegAdminCmd("sm_jumpscare", Jumpscare, ADMFLAG_ROOT);
	
	//AddFileToDownloadsTable
	AddFileToDownloadsTable("materials/js/js1.vtf");
	AddFileToDownloadsTable("materials/js/js1.vmt");
	
	AddFileToDownloadsTable("sound/js/js.mp3");
	PrecacheSound("sound/js/js.mp3");
}

public Action:Jumpscare(client, args)
{
	new String:arg[64];
	GetCmdArg(1, arg, sizeof(arg));
	
	new target = FindTarget(client, arg);
	
	if (IsClientInGame(target) && (!IsFakeClient(target)) && IsPlayerAlive(target))
	{
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
		ClientCommand(target, "r_screenoverlay \"js/js1.vtf\"");
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") | FCVAR_CHEAT);
		
		//EmitSoundToClient(target, "js/js1.mp3");
		// Yes im too lazy to understand EmitSoundToClient. It wouldnt precache properly.
		ServerCommand("sm_play #%d \"js/js.mp3\"", GetClientUserId(target));
		
		CreateTimer(2.0, RemoveOverlayTimer, target);
		PrintToChat(client, "Successfully scared the crap out of %N", target);
		
		if(client != target)
		{
			PrintToChat(target, "You've been jumpscared by %N", client);
		}
	}
	else if(!IsPlayerAlive(target))
	{
		PrintToChat(client, "Target is not alive, thus we cannot jumpscare them.");
	}
	return Plugin_Handled;
}

public Action:RemoveOverlayTimer(Handle:timer, any:target)
{
	if (IsClientInGame(target) && (!IsFakeClient(target)))
	{
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
		ClientCommand(target, "r_screenoverlay \"0\"");
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") | FCVAR_CHEAT);
	}
}