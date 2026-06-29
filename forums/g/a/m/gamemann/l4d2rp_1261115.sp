#include <sourcemod>
#include <sdktools>


//random choices
new Handle:PlayerDeathE = INVALID_HANDLE;
new Handle:HealthE = INVALID_HANDLE;
new Handle:HordeE = INVALID_HANDLE;
new Handle:NewBotE = INVALID_HANDLE;
new Handle:WeaponPackE = INVALID_HANDLE;
new Handle:NothingE = INVALID_HANDLE;
new Handle:MaxMobSizeE = INVALID_HANDLE;
new Handle:MinMobSizeE = INVALID_HANDLE;
new Handle:ForeverMobE = INVALID_HANDLE;
new Handle:HealthPackE = INVALID_HANDLE;


//other
new Handle:AdvertE = INVALID_HANDLE;

public Plugin:myinfo = {
    name = "rp_mod",
    author = "gamemann",
    description = "A rtd mod for l4d2",
    version = "1.0",
    url = "games223.com"
};

public OnPluginStart()
{
	//convars
	WeaponPackE = CreateConVar("weapon_pack_choice", "1", "enable weapon pack random pick");
	NothingE = CreateConVar("nothing_choice", "1", "enable the nothing choice");
	MaxMobSizeE = CreateConVar("50%_increase_mob_choice", "1", "enable the random pick where the mobs are increased to 50% more, 60 size");
	MinMobSizeE = CreateConVar("50%_decrease_mob_choice", "1", "enable the random pick where the mobs are decreased by 50% less, 15 size");
	ForeverMobE = CreateConVar("forever_mob_choice", "1", "enable the random pick where the mobs never stop when one comes");
	HealthPackE = CreateConVar("health_pack_choice", "1", "enable the random pick where you get pain pills and a first aid kit!");
	PlayerDeathE = CreateConVar("player_death_choice", "1", "enable player death in random pick");
	HealthE = CreateConVar("health_choice", "1", "Enable health random pick");
	HordeE = CreateConVar("horde_choice", "1", "Enable horde random pick");
	NewBotE = CreateConVar("new_bot_choice", "1", "enable random pick");
	AdvertE = CreateConVar("advert_enable", "1", "enable advertisement or not");
	//reg cmds
	RegConsoleCmd("sm_rp", CmdPick);
	//advert
	HookEvent("round_start", RoundStart);
	AutoExecConfig(true, "l4d2_rp");
}

public Action:CmdPick(client, args)
{
    new RandomPick = GetRandomInt(1,10);
    switch(RandomPick)
    {
        case 1:
        {
			if(GetConVarInt(HealthE))
			IsClientInGame(client)
			FakeClientCommand(client, "give health");
        }
        case 2:
        {
			
			if(GetConVarInt(NewBotE))
			IsClientInGame(client)
			if (GetClientTeam(client) == 3)
			{
				new bot = CreateFakeClient("infected bot");
				ChangeClientTeam(bot, 3);
				DispatchSpawn(bot);
				DispatchKeyValue(bot,"classname","InfectedBot");
				CreateTimer(1.0,InfectedKicker,bot);
			}
			if (GetClientTeam(client)==2)
			{
				new bot = CreateFakeClient("infected bot");
				ChangeClientTeam(bot, 3);
				DispatchSpawn(bot);
				DispatchKeyValue(bot,"classname","InfectedBot");
				CreateTimer(1.0, SurvivorKicker,bot);
			}
        }
        case 3:
        {
            if(GetConVarInt(PlayerDeathE))
			IsClientInGame(client)
            FakeClientCommand(client, "kill");
        }
        case 4:
        {
            if(GetConVarInt(HordeE))
			IsClientInGame(client)
            FakeClientCommand(client, "director_force_panic_event 1");
        }
        case 5:
        {
			if(GetConVarInt(NothingE))
			IsClientInGame(client)
			PrintToChat(client, "hahaha you get nothing!");
			
        }
		case 6:
		{
			if(GetConVarInt(WeaponPackE))
			IsClientInGame(client)
			FakeClientCommand(client, "give rifle");
			FakeClientCommand(client, "give molotov");
		}	
		case 7:
		{
			if(GetConVarInt(MaxMobSizeE))
			IsClientInGame(client)
			PrintToChatAll("\x05 someone just randomly picked a choice where the mobs size is 50% big!");
			FakeClientCommand(client, "z_mob_spawn_max_size 60");
		}
		case 8:
		{
			if(GetConVarInt(MinMobSizeE))
			IsClientInGame(client)
			PrintToChatAll("\x04 someone randomly picked a choice where the mobs size is 50% smaller!");
			FakeClientCommand(client, "z_mob_spawn_max_size 15");
		}
		case 9:
		{
			if(GetConVarInt(ForeverMobE))
			IsClientInGame(client)
			PrintToChatAll("\x03 someone randomly picked a choice where the mobs never end bad luck for the survivors!");
			FakeClientCommand(client, "director_panic_forever 1");
		}
		case 10:
		{
			if(GetConVarInt(HealthPackE))
			IsClientInGame(client)
			FakeClientCommand(client, "give first_aid_kit");
			FakeClientCommand(client, "give pain_pills");
			PrintToChat(client, "\x02 you have all health items!");
		}
    }
    return Plugin_Handled;
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(GetConVarInt(AdvertE))
        for (new i = 1; i <= MaxClients; i++)
            if (IsClientInGame(i))
                PrintToChat(i, "\x05 this server is running \x04 rp_mod so type in the chat !rp and you get a random thing!");
}


public Action:SurvivorKicker(Handle:timer, any:value)
{
    KickClient(value, "survivor bot");
    return Plugin_Handled;
}

public Action:InfectedKicker(Handle:timer, any:value)
{
    KickClient(value, "infected bot");
    return Plugin_Handled;
}  