#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = {
	name = "song box",
	author = "gamemann",
	description = "hahahahha a song box type in the chatbox !songbox",
	version = "1.0",
	url = ""
};

//songs
new String:fireflies[255] = "songs/OwlCityFireflies.mp3";
new Handle:song_volume = INVALID_HANDLE;

public OnPluginStart()
{
	song_volume = CreateConVar("song_volume", "0.5", "the songs volume");
	RegConsoleCmd("sm_songbox", Songs);
	AutoExecConfig(true, "song_box");
}

public SongPrecache()
{
	PrecacheSound(fireflies, true);
}

public Action:Songs(client, args)
{
	new Handle:menu = CreateMenu(songsmenu);
	SetMenuTitle(menu, "songs menu (listen to your favorite songs)");
	AddMenuItem(menu, "option0", "owl city- fireflies");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	//return 0;
}

public songsmenu(Handle:menu, MenuAction:action, client, itemNum)
{
	if(action == MenuAction_Select)
	{
		switch (itemNum)
		{
			case 0:
			{
				new Float:vecPos[3];
				GetClientAbsOrigin(client, vecPos)
				EmitSoundToAll(fireflies, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, GetConVarFloat(song_volume), SNDPITCH_NORMAL, -1, vecPos, NULL_VECTOR, true, 0.0);
			}
		}
	}
}