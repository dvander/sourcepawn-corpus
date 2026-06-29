#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdktools>

#define PLUGIN_VERSION "0.1"

new Handle:cvar_uber_on	= INVALID_HANDLE
new Handle:cvar_max_player = INVALID_HANDLE
new Handle:cvar_chat_interval = INVALID_HANDLE
public Plugin:myinfo = 
{
	name = "AutoChatMedic'sUberLevel",
	author = "GUN-KATANAMAN",
	description = "Our team can know our team medic's uber chage level",
	version = PLUGIN_VERSION,
	url = ""
};

// c gengo de iu main(){} no koto
public OnPluginStart(){
	//cvar wo sakusei
	CreateConVar("g_uber_version",PLUGIN_VERSION,"Our team can know our team medic's uber chage",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	//cvar wo sakusei site handle ni dainyuu
	cvar_uber_on = CreateConVar("g_acmul_enable","1","Our team can know our team medic's uber chage level 1=TRUE 0=FALSE DEFAULT=1");
	//player no saidai ninn zuu
	cvar_max_player = CreateConVar("g_max_player","24","Number of max player DEFAULT=24");
	//chat interval
	cvar_chat_interval = CreateConVar("g_chat_interval","5","Chat interval DEFAULT=5(s)");

	}

// When a new client connects we reset their flags
//player ga join sitekita tokini timer wo hatudou saseru
public OnClientPutInServer(client)
{
	CreateTimer(float(GetConVarInt(cvar_chat_interval)), Chat_Team, client,TIMER_REPEAT);
}


//chat wo team ni suru
public Action:Chat_Team(Handle:timer, any:client)
{
	//class no zyouhou wo get suru
	new TFClassType:class = TF2_GetPlayerClass(client);
	//medic no baai syori wo suru
	if (class == TFClass_Medic && GetConVarInt(cvar_uber_on)){
		//game ni iru ka dou ka nazeka hitu you rasii
		if (IsClientInGame(client))
		{
			//player no buki no zyoutai wo syutoku
			new index = GetPlayerWeaponSlot(client, 1);
			if(index>0){
				new i;
				//player no ninzuu bun chat wo okuru hantei wo suru
				for(i=1;GetConVarInt(cvar_max_player)+1>i;i++)
				{
					if(GetClientTeam(client)==GetClientTeam(i)){						
						new Float:dummy=GetEntPropFloat(index, Prop_Send, "m_flChargeLevel")*100;
						PrintToChat(i,"\x01%d\x01.Medic's \x01\x04%.0f\x01\%",client,dummy);
					}
				}
			}
		}
	}
}