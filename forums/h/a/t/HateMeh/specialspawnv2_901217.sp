#define PLUGIN_VERSION "1.0.7"
#define PLUGIN_NAME "Special Spawn [L4D]"
#include <sourcemod>
#include <sdktools>
public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "HateMeh",
	description = "Spawns x number of specials",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=901217"
}
public OnPluginStart()
{
	RegAdminCmd("sm_give", Command_MyGive, ADMFLAG_KICK);
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_spawn", Command_MyWitch, ADMFLAG_KICK);
}
//witch
public Action:Command_MyWitch(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_spawn <name> <amount>, 100 max");
		return Plugin_Handled;
	}
	
	new String:arg1[32], String:arg2[32], String:check[32]
	new amount, i
	
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	amount = StringToInt(arg2);
	
	if(amount > 100)
	{
		amount = 100;
	}
	//weghalen van de cheat flag
	new spawnflags = GetCommandFlags("z_spawn");
	SetCommandFlags("z_spawn", spawnflags & ~FCVAR_CHEAT);
	
	//uitvoering fakeclient commands als i kleiner is dan amount
	while(i < amount)
	{
		check = "common"
		//als arg1 gelijk is aan "common" voer dit uit
		if(arg1[1] == check[1])
		{
			FakeClientCommand(client, "z_spawn %s", arg1);
		}
		//anders
		else{
			FakeClientCommand(client, "z_spawn %s auto", arg1);
			i++;
		}
	}
	SetCommandFlags("z_spawn", spawnflags|FCVAR_CHEAT);
	return Plugin_Continue;
}
//give
public Action:Command_MyGive(client, args)
{
	//als er geen argumenten met het command worden meegegeven doe niks
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_give <item> <name>");
		return Plugin_Handled;
	}
	//declaratie variables
	new String:arg1[32], String:arg2[32]
	GetCmdArg(1, arg1, sizeof(arg1))
	GetCmdArg(2, arg2, sizeof(arg2))
		//zoeken van target 
	new target = FindTarget(client, arg2)
	//als target niet bestaat stop uitvoeren code
	if (target == -1)
	{
		ReplyToCommand(client, "Usage: sm_give <item> <name>");
		return Plugin_Handled;
	}
	//weghalen cheat flag
	new spawnflags = GetCommandFlags("give");
	SetCommandFlags("give", spawnflags & ~FCVAR_CHEAT);
	//item geven aan speler
	FakeClientCommand(target, "give %s", arg1);
	//terugzetten van de cheat flag
	SetCommandFlags("give", spawnflags|FCVAR_CHEAT);
}
