#include sdktools

#define MAX_SOUNDS 50

new soundsnum=0;
new Handle:Sound_Menu = INVALID_HANDLE;
new soundToPlay[MAXPLAYERS+1];

enum SoundN{
	String:SoundName[64],
	String:SoundPath[PLATFORM_MAX_PATH],
};

new sounds[MAX_SOUNDS][SoundN];

public OnPluginStart()
{
	BuildSoundMenu();
	RegAdminCmd("sm_sounds",OpenSoundMenu,ADMFLAG_ROOT);
}

public Action:OpenSoundMenu(client,args)
{
	DisplayMenu(Sound_Menu,client,MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public Handler_SelectMenu(Handle:menu,MenuAction:action,client,item)
{
	if(action == MenuAction_Select)
	{
		decl String:info[20];
		new clientId;
		GetMenuItem(menu,item,info,sizeof(info));
		clientId = StringToInt(info);
		if(IsClientInGame(clientId))
		{
			PrecacheSound(sounds[soundToPlay[client]][SoundPath]);
			EmitSoundToAll(sounds[soundToPlay[client]][SoundPath],clientId);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Handler_SoundMenu(Handle:menu,MenuAction:action,client,item)
{
	if(action == MenuAction_Select)
	{
		new Handle:Select_Menu;
		decl String:info[20];
		decl String:namebuffer[50];
		decl String:numberbuffer[50];
		
		GetMenuItem(menu,item,info,sizeof(info));
		soundToPlay[client]=StringToInt(info);
		
		Select_Menu = CreateMenu(Handler_SelectMenu);
		SetMenuTitle(Select_Menu,"Select a Player");
		
		for (new i=1;i<=MaxClients;i++)
		{
			if(IsClientInGame(i))
			{
				IntToString(i,numberbuffer,sizeof(numberbuffer));
				GetClientName(i,namebuffer,sizeof(namebuffer));
				AddMenuItem(Select_Menu,numberbuffer,namebuffer);
			}
		}
		DisplayMenu(Select_Menu,client,MENU_TIME_FOREVER);
	}
}

public BuildSoundMenu()
{
	decl String:path[PLATFORM_MAX_PATH];
	if (Sound_Menu != INVALID_HANDLE)
	{
		CloseHandle(Sound_Menu);
	}
	Sound_Menu = CreateMenu(Handler_SoundMenu);
	SetMenuTitle(Sound_Menu,"Select a Sound");
	
	new Handle:kvSounds = CreateKeyValues("Sounds");
	BuildPath(Path_SM, path, sizeof(path), "configs/sounds.cfg");
	if (!FileToKeyValues(kvSounds, path))
	{
		SetFailState("\"%s\" missing from server", path);
	}
	decl String:soundname[64];
	decl String:soundnum[10];
	soundsnum=0;
	if (KvGotoFirstSubKey(kvSounds))
	{
		do
		{
			KvGetSectionName(kvSounds, soundname, sizeof(soundname));
			Format(sounds[soundsnum][SoundName], 63, "%s", soundname);
			
			KvGetString(kvSounds, "path", sounds[soundsnum][SoundPath],199);
			AddFileToDownloadsTable(sounds[soundsnum][SoundPath]);
			
			IntToString(soundsnum,soundnum,sizeof(soundnum));
			AddMenuItem(Sound_Menu,soundnum,sounds[soundsnum][SoundName]);
			
			soundsnum++;
		} while (KvGotoNextKey(kvSounds)&&soundsnum<MAX_SOUNDS);
	}
	SetMenuExitBackButton(Sound_Menu,true);
	CloseHandle(kvSounds);
}