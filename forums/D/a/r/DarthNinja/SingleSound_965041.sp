#include sourcemod
#include sdktools

#define Usersound  		"angryadmin.mp3"

public Plugin:myinfo = {
    name = "[SM] Single Sound",
    author = "DarthNinja",
    description = "Plays a single sound for a single player",
    version = "1.0",
    url = "www.AlliedMods.net"
};

 
public OnPluginStart()
	{
	RegAdminCmd("sm_singlesound", Command_SSound, ADMFLAG_KICK, "sm_singlesound <#userid|name> - Forces player(s) to taunt if alive");
	CreateConVar("SingleSoundVersion", "1.0", "Single Sound Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	}

public OnMapStart() 
	{
	PrecacheSound(Usersound)
	decl String:file[64]
	Format(file, 63, "sound/%s", Usersound);
	AddFileToDownloadsTable(file)
	}

public Action:Command_SSound(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_singlesound <#userid|name>");
		return Plugin_Handled;
	}
	
	new String:soundtarget[32];
	GetCmdArg(1, soundtarget, sizeof(soundtarget));
	new target = FindTarget(client, soundtarget);

	EmitSoundToClient(target, Usersound, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL)
	LogAction(client, target, "%L played sound %s to %L", client, Usersound, target);
	return Plugin_Handled;
}
