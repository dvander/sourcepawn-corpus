#include <sourcemod>
#include <sdktools>
#include <morecolors>

new String:Map_Name[64];

public Plugin:myinfo =
{
	name = "Pyramidduel2",
	author = "Skuzy",
	description = " plugin qui delete les bouton gravité , le func_breakable , la zone bombe et la bombe ",
	version = "1.0.0",
	url = " "
};

public OnMapStart()
{
	GetCurrentMap(Map_Name,sizeof(Map_Name));
}

public OnPluginStart()
{
	RegAdminCmd("sm_debug_pyra", DEBUG, ADMFLAG_ROOT);
	
	HookEvent("round_start", OnRoundStart_Callback);

}

public Action:DEBUG(client, args)
{
	if(StrEqual("surf_pyramidduel2",Map_Name,false))
	{
		DELETE_ENTITE_BOUTON();
		DELETE_BREACK();
		DELETE_BOMB_ZONE();
		DELETE_BOMB();
	}
	else
		PrintToChat(client,"Commande désactivée sur cette map!");
	return Plugin_Handled;
}

public Action:OnRoundStart_Callback(Handle:event, const String:name[], bool:dontBroadcast)
{	
	if(StrEqual("surf_pyramidduel2",Map_Name,false))
	{
		DELETE_ENTITE_BOUTON();
		DELETE_BREACK();
		DELETE_BOMB_ZONE();
		DELETE_BOMB();
	}
}

DELETE_ENTITE_BOUTON()
{
	decl String:s_Bouton[64];
	for(new i=GetMaxClients();i<=GetMaxEntities();i++)
	{
		if(IsValidEdict(i) && IsValidEntity(i))
		{
			GetEdictClassname(i, s_Bouton, sizeof(s_Bouton));
			if(StrContains(s_Bouton,"func_button")!=-1 && PosBouton(i) )
			{
				AcceptEntityInput(i,"kill");
			}
		}
	}
}

DELETE_BREACK()
{
	decl String:s_Breack[64];
	for(new i=GetMaxClients();i<=GetMaxEntities();i++)
	{
		if(IsValidEdict(i) && IsValidEntity(i))
		{
			GetEdictClassname(i, s_Breack, sizeof(s_Breack));
			if(StrContains(s_Breack,"func_breakable")!=-1 && PosBreak(i) )
			{
				AcceptEntityInput(i,"kill");
			}
		}
	}
}

DELETE_BOMB()
{
	decl String:s_C4[64];
	for(new i=GetMaxClients();i<=GetMaxEntities();i++)
	{
		if(IsValidEdict(i) && IsValidEntity(i))
		{
			GetEdictClassname(i, s_C4, sizeof(s_C4));
			if(StrContains(s_C4,"weapon_c4")!=-1)
			{
				AcceptEntityInput(i,"kill");
			}
		}
	}
}

DELETE_BOMB_ZONE()
{
	decl String:s_BombeZone[64];
	for(new i=GetMaxClients();i<=GetMaxEntities();i++)
	{
		if(IsValidEdict(i) && IsValidEntity(i))
		{
			GetEdictClassname(i, s_BombeZone, sizeof(s_BombeZone));
			if(StrContains(s_BombeZone,"func_bomb_target")!=-1)
			{
				AcceptEntityInput(i,"kill");
			}
		}
	}
}

stock bool:PosBouton(i)
{
	new Float:v[3];
	GetEntPropVector(i, Prop_Send, "m_vecOrigin", v);
	if (v[0] >= -13538.108398
		&& v[0] <= -13111.136719 
		&& v[1] >= 796.495605 
		&& v[1] <= 1275.863403 
		&& v[2] >= 14136.031250
		&& v[2] <= 14229.664062)return true;
	else
		return false;
}

stock bool:PosBreak(i)
{
	new Float:v[3];
	GetEntPropVector(i, Prop_Send, "m_vecOrigin", v);
	if (v[0] >= -13789.711914
		&& v[0] <= -13685.298828 
		&& v[1] >= 1456.750732 
		&& v[1] <= 1562.807617 
		&& v[2] >= 15045.052734
		&& v[2] <= 15411.651367)return true;
	else
		return false;
}