#include <sdktools>

public Plugin:myinfo = 
{
	name = "Add Buyzone",
	author = "kumpu",
	description = "Adds a buyzone if there is none",
	version = "1.0",
	url = ""
}
public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public OnMapStart()
{
	manageBuyZones();
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	manageBuyZones();
}

manageBuyZones()
{
    decl String:szClass[65];
    new bool:hasBuyZone = false;

    for (new i = MaxClients; i <= GetMaxEntities(); i++)
    {
        if(IsValidEdict(i) && IsValidEntity(i))
        {
            GetEdictClassname(i, szClass, sizeof(szClass));
            if(StrEqual("func_buyzone", szClass))
            {
                PrintToServer("has bz");
                hasBuyZone = true;
                break;
            }
        }
    }

    //if(!hasBuyZone)
    //{
        PrintToServer("add bz...");
        addBuyZoneBothTeams();
    //}
}

addBuyZoneBothTeams()
{
    new tClient = -1;
    new ctClient = -1;
    new curTeam;
    for (new i=1; i<=MaxClients; i++)
    {
        if(IsClientInGame(i))
        {
            curTeam = GetClientTeam(i);
            if(curTeam == 2){tClient = i;}
            if(curTeam == 3){ctClient = i;}
        }
    }

    if(tClient > -1)
    {
        new Float:pos[3];
        GetClientAbsOrigin(tClient, pos);
        addBuyZone(pos, "2");
        PrintToServer("add t");
    }
    if(ctClient > -1)
    {
        new Float:pos[3];
        GetClientAbsOrigin(ctClient, pos);
        addBuyZone(pos, "3");
        PrintToServer("add ct");
    }
}

addBuyZone(Float:position[3], String:team[2]) //team: 0=none,1=all,2=t,3=ct
{
    new ent = CreateEntityByName("func_buyzone");
    if (ent != -1)
    {
        DispatchKeyValue(ent, "team", team); 
    }

    DispatchSpawn(ent);
    ActivateEntity(ent);

    position[2] = position[2] -10;
    PrintToServer("pos0: %f, pos1: %f, pos2: %f", position[0], position[1], position[2]);
    
    TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
    PrecacheModel("models/props/cs_office/vending_machine.mdl", true);
    SetEntityModel(ent, "models/props/cs_office/vending_machine.mdl");

    new Float:minbounds[3] = {-500.0, -500.0, 0.0};
    new Float:maxbounds[3] = {500.0, 500.0, 500.0};
    SetEntPropVector(ent, Prop_Send, "m_vecMins", minbounds);
    SetEntPropVector(ent, Prop_Send, "m_vecMaxs", maxbounds);

    SetEntProp(ent, Prop_Send, "m_nSolidType", 2);

    new enteffects = GetEntProp(ent, Prop_Send, "m_fEffects");
    enteffects |= 32;
    SetEntProp(ent, Prop_Send, "m_fEffects", enteffects);
} 