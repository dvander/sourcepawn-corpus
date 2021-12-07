#define PLUGIN_VERSION "1.0.7"
#define PLUGIN_NAME "Special Spawn [L4D]"

#include <sourcemod>
#include <sdktools>
new Handle:nlimit, Handle:nexplo, Handle:nhunter, Handle:nboomer;
new olimit, oexplo, ohunter, oboomer
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
	nlimit = FindConVar("z_gas_limit");
	nexplo = FindConVar("z_exploding_limit");
	nhunter = FindConVar("z_hunter_limit");
	nboomer = FindConVar("z_versus_boomer_limit");
	olimit = GetConVarInt(nlimit);
	oexplo = GetConVarInt(nexplo);
	ohunter = GetConVarInt(nhunter);
	oboomer = GetConVarInt(nboomer);
}

//witch
public Action:Command_MyWitch(client, args)
{
if (args < 1)
    {
        ReplyToCommand(client, "Usage: sm_spawn <name> <amount>, 100 max");
        return Plugin_Handled;
    }
    new String:arg1[32], String:arg2[32]
    new amount, i

    GetCmdArg(1, arg1, sizeof(arg1));
    GetCmdArg(2, arg2, sizeof(arg2));
	amount = StringToInt(arg2);
    if(amount > 100)
    {
        amount = 100;
    }
    
    SetConVarInt(nlimit, 100);
    SetConVarInt(nexplo, 100);
    SetConVarInt(nhunter, 100);
    SetConVarInt(nboomer, 100);
    new spawnflags = GetCommandFlags("z_spawn");
    SetCommandFlags("z_spawn", spawnflags & ~FCVAR_CHEAT);
    while(i < amount)
        {
    
            FakeClientCommand(client, "z_spawn %s auto", arg1);
            i++;

        }    
            SetConVarInt(nlimit, olimit);
            SetConVarInt(nexplo, oexplo);
            SetConVarInt(nhunter, ohunter);
            SetConVarInt(nhunter, oboomer);
    SetCommandFlags("z_spawn", spawnflags|FCVAR_CHEAT);
    return Plugin_Continue;
}  

//give
public Action:Command_MyGive(client, args)
{
	if (args < 1)
    {
        ReplyToCommand(client, "Usage: sm_give <item> <name>");
        return Plugin_Handled;
    }
	
	new String:arg1[32], String:arg2[32]
	GetCmdArg(1, arg1, sizeof(arg1))
	GetCmdArg(2, arg2, sizeof(arg2))
	new target = FindTarget(client, arg2)
	
	if (target == -1)
	{
		ReplyToCommand(client, "Usage: sm_give <item> <name>");
		return Plugin_Handled;
	}
	
	

		
	new spawnflags = GetCommandFlags("give");
	SetCommandFlags("give", spawnflags & ~FCVAR_CHEAT);
	FakeClientCommand(target, "give %s", arg1);
	SetCommandFlags("give", spawnflags|FCVAR_CHEAT);
}
