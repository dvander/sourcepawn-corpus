#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>
#include <console>
#include <string>

#define PLUGIN_VERSION "1.0 CZ"
#define MAX_FILE_LEN 80
#pragma semicolon 1
new Handle:g_CvarSoundName = INVALID_HANDLE;
new String:g_soundName[MAX_FILE_LEN];
public Plugin:myinfo = 
			{
			    name = "Admin Connect Message",
			    author = "tumtum, r5053, Hopkync",
			    description = "Shows players connecting admins and play sound",
			    version = PLUGIN_VERSION,
			    url = ""
			};

public OnPluginStart()
			{
			    CreateConVar("sm_admsnd_ver", PLUGIN_VERSION, "Admin Connect Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
			    g_CvarSoundName = CreateConVar("sm_admsnd_sound", "music/admin/adminconnect.mp3", "Admin announce sound");
			}

public OnConfigsExecuted()
			    {
				GetConVarString(g_CvarSoundName, g_soundName, MAX_FILE_LEN);
				decl String:buffer[MAX_FILE_LEN];
				PrecacheSound(g_soundName, true);
				Format(buffer, sizeof(buffer), "sound/%s", g_soundName);
				AddFileToDownloadsTable(buffer);
			    }

public OnClientPostAdminCheck(client)
					{
					    new AdminId:id = GetUserAdmin(client);
					    if (id != INVALID_ADMIN_ID)
					    {
						new String:name[32];
						GetClientName(client, name, 32);
						PrintToChatAll("Admin \x04%s \x01connected!", name );
						EmitSoundToAll(g_soundName);
					    }
					    return true;
					}