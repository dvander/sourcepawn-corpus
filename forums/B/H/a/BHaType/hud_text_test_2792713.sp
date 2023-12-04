#include <sourcemod>
#include <sdktools>

enum
{
	HUD_MSG_FADE = 1, // fade in/fade out
	HUD_MSG_FLICKERY, // flickery credits
	HUD_MSG_WRITE // write out (training room)
};

public OnPluginStart()
{
	RegConsoleCmd("sm_hud_text", sm_hud_text);
	RegConsoleCmd("sm_hud_text_syn", sm_hud_text_syn);
}

public Action sm_hud_text_syn(int client, int args)
{
	static Handle syn;

	if (!syn)
		syn = CreateHudSynchronizer();
	
	SetHudTextParams(-1.0, -1.0, 5.35, 255, 255, 255, 255, HUD_MSG_FLICKERY, 0.0, 0.0, 0.0);
	ShowSyncHudText(client, syn, "Hello from hud synchronizer");
	return Plugin_Handled;
}

public Action sm_hud_text(int client, int args)
{
	PaintClientScreen(client, 1, -1.0, 0.6, "qwertyuiopasdfghjklzxcvbnm\nAlliedmodders", "255 25 255 255", "125 25 25 255", 5.0, HUD_MSG_FADE, 1.0, 1.0, 1.0);
	return Plugin_Handled;
}

void PaintClientScreen( int client, 
						int channel, 
						float x, 
						float y, 
						const char[] msg, 
						const char[] color, 
						const char[] color2, 
						float holdtime,
						int effect, 
						float fadein = 0.0, 
						float fadeout = 0.0, 
						float fxtime = 0.0)
{
	int game_text = CreateGameText(channel, x, y, msg, color, color2, holdtime, effect, fadein, fadeout, fxtime);
	DispatchKeyValue(game_text, "spawnflags", "0");
	SetVariantString("!activator");
	AcceptEntityInput(game_text, "display", client);	
}

stock void PaintClientScreenAll(	int channel, 
									float x, 
									float y, 
									const char[] msg, 
									const char[] color, 
									const char[] color2, 
									float holdtime,
									int effect, 
									float fadein = 0.0, 
									float fadeout = 0.0, 
									float fxtime = 0.0)
{
	int game_text = CreateGameText(channel, x, y, msg, color, color2, holdtime, effect, fadein, fadeout, fxtime);
	DispatchKeyValue(game_text, "spawnflags", "1");
	AcceptEntityInput(game_text, "display");	
}

int CreateGameText( int channel, 
					float x, 
					float y, 
					const char[] msg, 
					const char[] color, 
					const char[] color2, 
					float holdtime,
					int effect, 
					float fadein = 0.0, 
					float fadeout = 0.0, 
					float fxtime = 0.0)
{
	int game_text = CreateEntityByName("game_text");
	DispatchKeyValueInt(game_text, "channel", channel);
	DispatchKeyValue(game_text, "color", color);
	DispatchKeyValue(game_text, "color2", color2);
	DispatchKeyValueInt(game_text, "effect", effect);
	DispatchKeyValueFloat(game_text, "fadein", fadein);
	DispatchKeyValueFloat(game_text, "fadeout", fadeout);
	DispatchKeyValueFloat(game_text, "fxtime", fxtime);		 
	DispatchKeyValueFloat(game_text, "holdtime", holdtime);
	DispatchKeyValue(game_text, "message", msg);
	DispatchKeyValueFloat(game_text, "x", x);
	DispatchKeyValueFloat(game_text, "y", y);

	RequestFrame(NextFrame, EntIndexToEntRef(game_text));
	return game_text;
}

public void NextFrame(int game_text)
{
	game_text = EntRefToEntIndex(game_text);
	if (game_text && IsValidEntity(game_text))
		RemoveEntity(game_text);
} 

