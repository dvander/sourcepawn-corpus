#include <sourcemod>
#include <sdktools>

#pragma tabsize 0
/////////////////////////////////////////////////////////////////////////
ConVar Poke_Turu;
ConVar Ses;
/////////////////////////////////////////////////////////////////////////
public OnMapStart()
{
	//****************************************//			
	AddFileToDownloadsTable("sound/Plugincim_com/Poke.mp3");
	PrecacheSound("Plugincim_com/Poke.mp3");	
	//****************************************//
}
/////////////////////////////////////////////////////////////////////////
public OnPluginStart()
{
	//****************************************//			
	RegAdminCmd("sm_poke", Poke, ADMFLAG_GENERIC);
	//****************************************//
	Poke_Turu = CreateConVar("poke_type", "2", "Poke Type? ( 0 = Disable Msg || 1 = Only Chat || 2 = Chat + Hud )");
	Ses = CreateConVar("poke_sound", "1", "Poke Sound Enable or Disable? ( 1 - 0 )");
	//****************************************//
	LoadTranslations("common.phrases");
	//****************************************//		
}
/////////////////////////////////////////////////////////////////////////
public Action:Poke(client, args)
{
	//****************************************//		
	if(args == 1)
	{
		//****************************************//		
		char s_Hedef[32];
		GetCmdArg(1, s_Hedef, 32);
		//****************************************//				
		int Hedef = FindTarget(client, s_Hedef);
		if(Hedef)
		{
			//****************************************//
			if(GetConVarInt(Poke_Turu) == 1 || GetConVarInt(Poke_Turu) == 2)
				PrintToChat(Hedef, " \x02[POKE] \x0b%N \x01poked \x04you.", client);
			//****************************************//
			if(GetConVarInt(Poke_Turu) == 2)
			{
				new Handle:hHudText = CreateHudSynchronizer();
				SetHudTextParams(GetRandomFloat(-0.1, -1.0), GetRandomFloat(-0.1, -1.0), 5.0, GetRandomInt(1, 255), GetRandomInt(1, 255), GetRandomInt(1, 255), 255, 2, 0.1, 0.1, 0.1);
				ShowSyncHudText(Hedef, hHudText, "%N poked you.", client);
				CloseHandle(hHudText);	
			}
			//****************************************//
			if(GetConVarInt(Ses) == 1)
				EmitSoundToClient(Hedef, "Plugincim_com/Poke.mp3");
			//****************************************//				
		}
		else
			PrintToChat(client, " \x0bTarget \x02not found!");
		//****************************************//		
	}
	else
		PrintToChat(client, " \x0bUse: \x01!poke playername");
	//****************************************//			
}
/////////////////////////////////////////////////////////////////////////