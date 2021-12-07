#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0.1"
#define GIFT "models/props_halloween/halloween_gift.mdl"
#define INVIS					{255,255,255,0}
#define NORMAL					{255,255,255,255}

new g_FilteredEntity = -1;
new Float:g_ClientPosition[MAXPLAYERS+1][3];
new bool:g_IsGift[MAXPLAYERS+1] = { false, ...};

public Plugin:myinfo = 
{
    name = "[TF2] Fake Halloween Gifts",
    author = "DarthNinja",
    description = "For epic trolling!",
    version = PLUGIN_VERSION,
    url = "DarthNinja.com"
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	CreateConVar("sm_fakegifts_version", PLUGIN_VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)

	RegAdminCmd("sm_fakegift", FakeGift, ADMFLAG_CHEATS);
	RegAdminCmd("sm_makemegift", MakeMeAGift, ADMFLAG_CHEATS);
	
	HookEvent("post_inventory_application", EventInventoryApplication,  EventHookMode_Post);
}

public OnMapStart()
{
		PrecacheModel(GIFT);
}

public EventInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidEntity(client) && g_IsGift[client])
	{
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		Colorize(client, NORMAL);
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1)
		g_IsGift[client] = false;
		PrintToChat(client, "\x04[\x03FakeGift\x04]\x01: Your gift appearance has been removed!")
	}
}

public Action:FakeGift(client, args)
{
	if (client < 0)
	{
		ReplyToCommand(client, "Command must be used ingame!")
		return Plugin_Handled;
	}
	//TF_SpawnAmmopack(client, "item_ammopack_full", cmd);
	//TF_SpawnAmmopack(client, "item_ammopack_medium", cmd);
	TF_SpawnAmmopack(client, "item_ammopack_small", true);
	PrintToChat(client, "\x04[\x03FakeGift\x04]\x01: You have spawned a fake gift!")

	return Plugin_Handled;
}

public Action:MakeMeAGift(client, args)
{
	if (client < 0)
	{
		ReplyToCommand(client, "Command must be used ingame!")
		return Plugin_Handled;
	}
	
	if (IsPlayerAlive(client) && IsValidEntity(client) && !g_IsGift[client])
	{
		SetVariantString(GIFT);
		AcceptEntityInput(client, "SetCustomModel");
		SetVariantInt(1);
		AcceptEntityInput(client, "SetCustomModelRotates");
		Colorize(client, INVIS);
		
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1)
		g_IsGift[client] = true;
		PrintToChat(client, "\x04[\x03FakeGift\x04]\x01: You now look just like a gift!")
	}
	else if (IsValidEntity(client) && g_IsGift[client])
	{
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		Colorize(client, NORMAL);
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1)
		g_IsGift[client] = false;
		PrintToChat(client, "\x04[\x03FakeGift\x04]\x01: Your gift appearance has been removed!")
	}
	
	return Plugin_Handled;
}

stock TF_SpawnAmmopack(client, String:name[], bool:cmd)
{
    new Float:PlayerPosition[3];
    if (cmd)
        GetClientAbsOrigin(client, PlayerPosition);
    else
        PlayerPosition = g_ClientPosition[client];

    if (PlayerPosition[0] != 0.0 && PlayerPosition[1] != 0.0 && PlayerPosition[2] != 0.0 && IsEntLimitReached() == false)
    {
        PlayerPosition[2] += 4;
        g_FilteredEntity = client;
        if (cmd)
        {
            new Float:PlayerPosEx[3], Float:PlayerAngle[3], Float:PlayerPosAway[3];
            GetClientEyeAngles(client, PlayerAngle);
            PlayerPosEx[0] = Cosine((PlayerAngle[1]/180)*FLOAT_PI);
            PlayerPosEx[1] = Sine((PlayerAngle[1]/180)*FLOAT_PI);
            PlayerPosEx[2] = 0.0;
            ScaleVector(PlayerPosEx, 75.0);
            AddVectors(PlayerPosition, PlayerPosEx, PlayerPosAway);

            new Handle:TraceEx = TR_TraceRayFilterEx(PlayerPosition, PlayerPosAway, MASK_SOLID, RayType_EndPoint, AmmopackTraceFilter);
            TR_GetEndPosition(PlayerPosition, TraceEx);
            CloseHandle(TraceEx);
        }

        new Float:Direction[3];
        Direction[0] = PlayerPosition[0];
        Direction[1] = PlayerPosition[1];
        Direction[2] = PlayerPosition[2]-1024;
        new Handle:Trace = TR_TraceRayFilterEx(PlayerPosition, Direction, MASK_SOLID, RayType_EndPoint, AmmopackTraceFilter);

        new Float:AmmoPos[3];
        TR_GetEndPosition(AmmoPos, Trace);
        CloseHandle(Trace);
        AmmoPos[2] += 4;

        new Ammopack = CreateEntityByName(name);
        DispatchKeyValue(Ammopack, "OnPlayerTouch", "!self,Kill,,0,-1");
        if (DispatchSpawn(Ammopack))
        {
            new team = 0;
            SetEntProp(Ammopack, Prop_Send, "m_iTeamNum", team, 4);
            SetEntityModel(Ammopack, GIFT)
            TeleportEntity(Ammopack, AmmoPos, NULL_VECTOR, NULL_VECTOR);
        }
    }
}

public bool:AmmopackTraceFilter(ent, contentMask)
{
    return (ent != g_FilteredEntity);
}

stock bool:IsEntLimitReached()
{
    if (GetEntityCount() >= (GetMaxEntities()-16))
    {
        PrintToServer("Warning: Entity limit is nearly reached! Please switch or reload the map!");
        LogError("Entity limit is nearly reached: %d/%d", GetEntityCount(), GetMaxEntities());
        return true;
    }
    else
        return false;
}

/*
Credit to pheadxdll for invisibility code.
*/
public Colorize(client, color[4])
{	
	//Colorize the weapons
	new m_hMyWeapons = FindSendPropOffs("CBasePlayer", "m_hMyWeapons");	
	new String:classname[256];
	new type;
	new TFClassType:class = TF2_GetPlayerClass(client);
	
	for(new i = 0, weapon; i < 47; i += 4)
	{
		weapon = GetEntDataEnt2(client, m_hMyWeapons + i);
		
		if(weapon > -1 )
		{
			GetEdictClassname(weapon, classname, sizeof(classname));
			if((StrContains(classname, "tf_weapon_",false) >= 0))
			{
				SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
				SetEntityRenderColor(weapon, color[0], color[1], color[2], color[3]);
			}
		}
	}
	
	//Colorize the wearables, such as hats
	SetWearablesRGBA_Impl( client, "tf_wearable_item", "CTFWearableItem",color );
	SetWearablesRGBA_Impl( client, "tf_wearable_item_demoshield", "CTFWearableItemDemoShield", color);
	
	//Colorize the player
	//SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	//SetEntityRenderColor(client, color[0], color[1], color[2], color[3]);
	
	if(color[3] > 0)
	type = 1;
	
	InvisibleHideFixes(client, class, type);
	return;
}

SetWearablesRGBA_Impl( client,  const String:entClass[], const String:serverClass[], color[4])
{
	new ent = -1;
	while( (ent = FindEntityByClassname(ent, entClass)) != -1 )
	{
		if ( IsValidEntity(ent) )
		{		
			if (GetEntDataEnt2(ent, FindSendPropOffs(serverClass, "m_hOwnerEntity")) == client)
			{
				SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
				SetEntityRenderColor(ent, color[0], color[1], color[2], color[3]);
			}
		}
	}
}

InvisibleHideFixes(client, TFClassType:class, type)
{
	if(class == TFClass_DemoMan)
	{
		new decapitations = GetEntProp(client, Prop_Send, "m_iDecapitations");
		if(decapitations >= 1)
		{
			if(!type)
			{
				//Removes Glowing Eye
				TF2_RemoveCond(client, 18);
			}
			else
			{
				//Add Glowing Eye
				TF2_AddCond(client, 18);
			}
		}
	}
	else if(class == TFClass_Spy)
	{
		new disguiseWeapon = GetEntPropEnt(client, Prop_Send, "m_hDisguiseWeapon");
		if(IsValidEntity(disguiseWeapon))
		{
			if(!type)
			{
				SetEntityRenderMode(disguiseWeapon , RENDER_TRANSCOLOR);
				new color[4] = INVIS;
				SetEntityRenderColor(disguiseWeapon , color[0], color[1], color[2], color[3]);
			}
			else
			{
				SetEntityRenderMode(disguiseWeapon , RENDER_TRANSCOLOR);
				new color[4] = NORMAL;
				SetEntityRenderColor(disguiseWeapon , color[0], color[1], color[2], color[3]);
			}
		}
	}
}


//This won't be required in the future as Sourcemod 1.4 already has this stuff
stock TF2_AddCond(client, cond) {
	new Handle:cvar = FindConVar("sv_cheats"), bool:enabled = GetConVarBool(cvar), flags = GetConVarFlags(cvar);
	if(!enabled) {
		SetConVarFlags(cvar, flags^FCVAR_NOTIFY^FCVAR_REPLICATED);
		SetConVarBool(cvar, true);
	}
	FakeClientCommand(client, "addcond %i", cond);
	//FakeClientCommand(client, "isLoser");
	if(!enabled) {
		SetConVarBool(cvar, false);
		SetConVarFlags(cvar, flags);
	}
}

stock TF2_RemoveCond(client, cond) {
	new Handle:cvar = FindConVar("sv_cheats"), bool:enabled = GetConVarBool(cvar), flags = GetConVarFlags(cvar);
	if(!enabled) {
		SetConVarFlags(cvar, flags^FCVAR_NOTIFY^FCVAR_REPLICATED);
		SetConVarBool(cvar, true);
	}
	FakeClientCommand(client, "removecond %i", cond);
	if(!enabled) {
		SetConVarBool(cvar, false);
		SetConVarFlags(cvar, flags);
	}
}