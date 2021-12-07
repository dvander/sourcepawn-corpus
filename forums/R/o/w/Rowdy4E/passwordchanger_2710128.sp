#pragma semicolon 1

#define DEBUG

#define PLUGIN_NAME "Password Changer"
#define PLUGIN_AUTHOR "Rowdy4E."
#define PLUGIN_URL "https://steamcommunity.com/profiles/76561198307962930"
#define PLUGIN_DESC "Password changer. One or multiple passwords."
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

char cConfigFile[255];
ArrayList passwords;

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};


public void OnMapStart() {
	LoadConfig();
	setNextPassword();
}

void setNextPassword() {
	if (passwords.Length == 0)
		return;
	
	char cPassword[128];
	GetConVarString(FindConVar("sv_password"), cPassword, sizeof(cPassword));
	
	int index = FindStringInArray(passwords, cPassword);
	if (index != -1 && (passwords.Length-1) > index) {
		index++;
	} else {
		index = 0;
	}
			
	passwords.GetString(index, cPassword, sizeof(cPassword));
	SetConVarString(FindConVar("sv_password"), cPassword);
	
	for (int m = 0; m < 3; m++) {
		PrintToServer("***[%s] Current sv_password: %s", PLUGIN_NAME, cPassword);
	}
}

void LoadConfig() {
	passwords = CreateArray(128);
	
	BuildPath(Path_SM, cConfigFile, sizeof(cConfigFile), "configs/ServerPasswords.cfg");
	Handle file;
	
	if (!FileExists(cConfigFile)) {
		file = OpenFile(cConfigFile, "w");
		if (file != null) {
			WriteFileLine(file, "password_1\npassword_2\npassword_3");
			delete file;
		}
	}
	
	file = OpenFile(cConfigFile, "r");
	if (file != null) {
		char buffer[255];
		while (ReadFileLine(file, buffer, sizeof(buffer))) {
			if (strlen(buffer) > 0 && buffer[strlen(buffer) - 1] == '\n')
         		 buffer[strlen(buffer) - 1] = '\0';
			
			TrimString(buffer);
				
			if (strlen(buffer) == 0)
				continue;
				
			PushArrayString(passwords, buffer);
		}
		
		delete file;
	}
}
