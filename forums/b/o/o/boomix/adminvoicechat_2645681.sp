#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "boomix"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

int g_iPlayerPrevButtons[MAXPLAYERS + 1];
int iCounter[MAXPLAYERS + 1];
bool g_OnceStopped[MAXPLAYERS + 1];
Handle resetTmr[MAXPLAYERS + 1] = null;
bool bAdminVoiceChat[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Admin voice chat",
	author = PLUGIN_AUTHOR,
	description = "Admin voice chat on double E press",
	version = PLUGIN_VERSION,
	url = "https://identy.lv"
};

public void OnClientDisconnect(int client)
{
	if(bAdminVoiceChat[client])
		bAdminVoiceChat[client] = false;
}

public Action OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVelocity[3], float fAngles[3], int &iWeapon) 
{
	
	//On first E press
	if(!(g_iPlayerPrevButtons[client] & IN_USE) && iButtons & IN_USE) {

		//Counter
		iCounter[client]++;
		if(iCounter[client] == 2)
			TriggerAdminVoiceChat(client);
		
		//Kill reset timer
		if(resetTmr[client] != null && resetTmr[client] != INVALID_HANDLE)
		{
			KillTimer(resetTmr[client]);
			resetTmr[client] = null;
		}			
		resetTmr[client] = CreateTimer(0.3, ResetCounter, GetClientUserId(client));
			
		g_OnceStopped[client] = true;
	}
	
	//Still holding E
	else if (iButtons & IN_USE) {
		
	}
	
	//Stops pressing E
	else if(g_OnceStopped[client]) {
		
		//Remove message faster
		if(!bAdminVoiceChat[client])
			PrintHintText(client, " ");
			
		g_OnceStopped[client] = false;
	}
	
	g_iPlayerPrevButtons[client] = iButtons;
	
	
	//Display message
	bool ImSpeaking = false;
	bool othersSpeaking = false;
	for (int i = 1; i < MaxClients; i++)
	{
		if(bAdminVoiceChat[i] && i == client)
			ImSpeaking = true;
			
		else if(bAdminVoiceChat[i] && i != client)
			othersSpeaking = true;
	}
	
	if(ImSpeaking || othersSpeaking)
	{
		PrintHintText(
			client, 
			"<pre><font face=''>My admin voice: \t\t<font color='#%s'>%s</font>\nOther admin chat: \t<font color='#%s'>%s</font></font></pre>", 
			((ImSpeaking) ? "2CDA37" : "E30C0C"), 
			((ImSpeaking) ? "ON" : "OFF"), 
			((othersSpeaking) ? "2CDA37" : "E30C0C"),
			((othersSpeaking) ? "ON" : "OFF")
		);
	}

	
}

public void OnClientConnected(int client)
{
	bAdminVoiceChat[client] = false;
	//On new connection update listening flags
	for (int i = 1; i < MaxClients; i++)
		if(IsClientInGame(i) && bAdminVoiceChat[i]) 
			SetListenOverride(client, i, (HasPermission(client, "b") ? Listen_Yes : Listen_No));

}

void TriggerAdminVoiceChat(int client)
{
	if(HasPermission(client, "b")) 
	{
		bAdminVoiceChat[client] = (bAdminVoiceChat[client]) ? false : true;
		
		if(bAdminVoiceChat[client]) {
		
			//Set listening flags
			for (int i = 1; i < MaxClients; i++)
				if(IsClientInGame(i))
					SetListenOverride(i, client, (HasPermission(i, "b") ? Listen_Yes : Listen_No));
				
		} else {
			
			//Set default listening flags
			for (int i = 1; i < MaxClients; i++)
				if(IsClientInGame(i))
					SetListenOverride(i, client, Listen_Default);
			
		}
	}
}

public Action ResetCounter(Handle tmr, any userID)
{
	int client = GetClientOfUserId(userID);
	if(client > 0) 
	{
		iCounter[client] = 0;
		resetTmr[client] = null;
	}
}

stock bool HasPermission(int iClient, char[] flagString) 
{
	if (StrEqual(flagString, "")) 
	{
		return true;
	}
	
	AdminId admin = GetUserAdmin(iClient);
	
	if (admin != INVALID_ADMIN_ID)
	{
		int count, found, flags = ReadFlagString(flagString);
		for (int i = 0; i <= 20; i++) 
		{
			if (flags & (1<<i)) 
			{
				count++;
				
				if (GetAdminFlag(admin, view_as<AdminFlag>(i))) 
				{
					found++;
				}
			}
		}

		if (count == found) {
			return true;
		}
	}

	return false;
}