// Chat with bubbles

#include <sourcemod>
#include <basecomm>
#include <tf2>
#include <tf2_stocks>
#include <clientprefs>
#include <regex>

#undef REQUIRE_PLUGIN
#tryinclude <scp>
#tryinclude <chat-processor>
#tryinclude <CiderChatProcessor>
#define REQUIRE_PLUGIN

#include "tf2hudmsg.inc"

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "23w45a"

#define COOKIE_STATE "clientChatbubbleState"

public Plugin myinfo = {
	name = "[TF2] Chat Bubbles",
	author = "code: reBane, idea: fuffeh",
	description = "Talk in bubbles",
	version = PLUGIN_VERSION,
	url = "N/A"
}

#if defined _scp_included || defined _CiderChatProcessor_included || defined _chat_processor_included
#define _use_chatprocessor
// this is important if compiled for multiple processors and for some reason multiple processors are loaded on the server
#define CHAT_PROCESSOR_SCPREDUX (1<<0)
#define CHAT_PROCESSOR_CIDER (1<<1)
#define CHAT_PROCESSOR_DRIXEVEL (1<<2)
int chatProcessorLoaded;
#endif

/** allow to use a bitflag-like for the extended 100 players on tf2 */
enum struct PlayerBits {
	int partition[4]; // up to 128 players
	
	void Or(int index) {
		this.partition[index/32] |= (1<<(index%32));
	}
	void OrBits(PlayerBits other) {
		this.partition[0] |= other.partition[0];
		this.partition[1] |= other.partition[1];
		this.partition[2] |= other.partition[2];
		this.partition[3] |= other.partition[3];
	}
	void OrNot(int index) {
		this.partition[index/32] |=~ (1<<(index%32));
	}
	void OrNotBits(PlayerBits other) {
		this.partition[0] |=~ other.partition[0];
		this.partition[1] |=~ other.partition[1];
		this.partition[2] |=~ other.partition[2];
		this.partition[3] |=~ other.partition[3];
	}
	void And(int index) {
		this.partition[index/32] &= (1<<(index%32));
	}
	void AndBits(PlayerBits other) {
		this.partition[0] &= other.partition[0];
		this.partition[1] &= other.partition[1];
		this.partition[2] &= other.partition[2];
		this.partition[3] &= other.partition[3];
	}
	void AndNot(int index) {
		this.partition[index/32] &=~ (1<<(index%32));
	}
	void AndNotBits(PlayerBits other) {
		this.partition[0] &=~ other.partition[0];
		this.partition[1] &=~ other.partition[1];
		this.partition[2] &=~ other.partition[2];
		this.partition[3] &=~ other.partition[3];
	}
	bool Xor(int index) {
		int part = index/32;
		int mask = (1<<(index%32));
		this.partition[part] ^= mask;
		return (this.partition[part] & mask) != 0;
	}
	void XorBits(PlayerBits other) {
		this.partition[0] ^= other.partition[0];
		this.partition[1] ^= other.partition[1];
		this.partition[2] ^= other.partition[2];
		this.partition[3] ^= other.partition[3];
	}
	void Not() {
		this.partition[0] =~ this.partition[0];
		this.partition[1] =~ this.partition[1];
		this.partition[2] =~ this.partition[2];
		this.partition[3] =~ this.partition[3];
	}
	void Set(int index, bool active) {
		if (active) this.Or(index);
		else this.AndNot(index);
	}
	bool Get(int index) {
		return (this.partition[index/32] & (1<<(index%32))) != 0;
	}
	
	void SetTeam(int team) {
		for (int client=1; client <= MaxClients; client++)
			if (IsClientInGame(client) && GetClientTeam(client) == team)
				this.Or(client);
	}
	void SetAlive() {
		for (int client=1; client <= MaxClients; client++)
			if (IsClientInGame(client) && IsPlayerAlive(client))
				this.Or(client);
	}
	int ToArray(int[] player, int maxplayers) {
		int i;
		for (int client=1; client <= MaxClients && i < maxplayers; client++) {
			if (this.Get(client)) { 
				player[i] = client;
				i++;
			}
		}
		return i;
	}
	int ToArrayList(ArrayList list) {
		for (int client=1; client <= MaxClients; client++) {
			if (this.Get(client)) { 
				list.Push(client);
			}
		}
		return list.Length;
	}
	bool Any() {
		return this.partition[0] || this.partition[1] || this.partition[2] || this.partition[3];
	}
	int Count() {
		int count;
		for (int i=0; i<32; i++) {
			count += ((this.partition[0] & (1<<i)) ? 1 : 0) +
					((this.partition[1] & (1<<i)) ? 1 : 0) +
					((this.partition[2] & (1<<i)) ? 1 : 0) +
					((this.partition[3] & (1<<i)) ? 1 : 0);
		}
		return count;
	}
}

PlayerBits teamRedBits, teamBlueBits, aliveBits;
PlayerBits canSeeBits[MAXPLAYERS+1];
PlayerBits cookieEnabledBits;
PlayerBits cookieHiddenBits;

Cookie cookie_ClientSetting;
ConVar cvar_BubbleDistance;
ConVar cvar_BubbleEnabled;
ConVar cvar_BubbleDefaultState;
float cval_BubbleDistance;
int cval_BubbleEnabled;
int cval_BubbleDefaultState;

static Handle playerTraceTimer;
static Regex wordBreakPattern;

public void OnPluginStart() {
	AddCommandListener(commandSay, "say");
	AddCommandListener(commandSayTeam, "say_team");
	
	cvar_BubbleDistance = CreateConVar("sm_chatbubble_distance", "500", "Maximum distance in hammer units to display chat bubble for", FCVAR_ARCHIVE|FCVAR_NOTIFY, true, 50.0);
	cvar_BubbleEnabled = CreateConVar("sm_chatbubble_enabled", "1", "0 = disabled, 1 = say & teamsay, 2 = teamsay only", FCVAR_ARCHIVE|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	cvar_BubbleDefaultState = CreateConVar("sm_chatbubble_default", "1", "Default state of chat bubbles for players: 0 = disabled, 1 = enabled, 2 = hidden (send, don't show)", FCVAR_ARCHIVE|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	cvar_BubbleDistance.AddChangeHook(OnConVarChanged);
	cvar_BubbleEnabled.AddChangeHook(OnConVarChanged);
	cvar_BubbleDefaultState.AddChangeHook(OnConVarChanged);
	OnConVarChanged(null,"","");
	
	cookie_ClientSetting = new Cookie(COOKIE_STATE, "Chat bubbles visibility: 0=off,1=on,2=hidden", CookieAccess_Private);
	SetCookieMenuItem(cookieMenuHandler, 0, "Chat Bubbles");
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	
	// pattern to find clusters of 50 characters with a finishing cluster of up to 50
	wordBreakPattern = new Regex("[^\\s\\n]{50,100}", PCRE_UTF8|PCRE_MULTILINE);
	
	aliveBits.SetAlive();
	teamRedBits.SetTeam(view_as<int>(TFTeam_Red));
	teamBlueBits.SetTeam(view_as<int>(TFTeam_Blue));
	for (int i=1; i<=MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i)) {
			if(AreClientCookiesCached(i)) {
				OnClientCookiesCached(i);
			}
		}
	}
	
	PrintToChatAll("[Chat Bubbles] Version %s loaded!", PLUGIN_VERSION);
}

public void OnPluginEnd() {
	OnMapEnd();
}

#if defined _use_chatprocessor
public void OnLibraryAdded(const char[] name) {
	if (StrEqual(name, "scp")) chatProcessorLoaded |= CHAT_PROCESSOR_SCPREDUX;
	if (StrEqual(name, "CiderChatProcessor")) chatProcessorLoaded |= CHAT_PROCESSOR_CIDER;
	if (StrEqual(name, "chat-processor")) chatProcessorLoaded |= CHAT_PROCESSOR_DRIXEVEL;
}
public void OnLibraryRemoved(const char[] name) {
	if (StrEqual(name, "scp")) chatProcessorLoaded &=~ CHAT_PROCESSOR_SCPREDUX;
	if (StrEqual(name, "CiderChatProcessor")) chatProcessorLoaded &=~ CHAT_PROCESSOR_CIDER;
	if (StrEqual(name, "chat-processor")) chatProcessorLoaded &=~ CHAT_PROCESSOR_DRIXEVEL;
}
public void OnAllPluginsLoaded() {
	chatProcessorLoaded = 0;
	if (LibraryExists("scp")) chatProcessorLoaded |= CHAT_PROCESSOR_SCPREDUX;
	if (LibraryExists("CiderChatProcessor")) chatProcessorLoaded |= CHAT_PROCESSOR_CIDER;
	if (LibraryExists("chat-processor")) chatProcessorLoaded |= CHAT_PROCESSOR_DRIXEVEL;
}
#endif

public void OnMapStart() {
	if (playerTraceTimer == INVALID_HANDLE)
		playerTraceTimer = CreateTimer(0.1, Timer_PlayerTracing, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}
public void OnMapEnd() {
	KillTimer(playerTraceTimer);
	playerTraceTimer = INVALID_HANDLE;
}

public Action Timer_PlayerTracing(Handle timer) {
	updateClientMasks();
	return Plugin_Continue;
}

public void OnClientCookiesCached(int client) {
	char buffer[2];
	int sstate;
	sstate = cval_BubbleDefaultState;
	if (cookie_ClientSetting != null) {
		GetClientCookie(client, cookie_ClientSetting, buffer, sizeof(buffer));
		if (buffer[0]==0) { // no value set yet, set default
			if (cval_BubbleDefaultState==0) //default disabled, sad
				SetClientCookie(client, cookie_ClientSetting, "0");
			else if (cval_BubbleDefaultState==2) //default hidden
				SetClientCookie(client, cookie_ClientSetting, "2");
			else //default enabled
				SetClientCookie(client, cookie_ClientSetting, "1");
		} else {
			sstate = StringToInt(buffer);
		}
	}
	cookieHiddenBits.Set(client, sstate != 1);
	cookieEnabledBits.Set(client, sstate != 0);
}

public void cookieMenuHandler(int client, CookieMenuAction action, any info, char[] buffer, int maxlen) {
	if(action == CookieMenuAction_SelectOption) {
		showSettingsMenu(client);
	}
}

void showSettingsMenu(int client) {
	Menu menu = new Menu(settingsMenuActionHandler);
	if (cookieEnabledBits.Get(client)) {
		if (cookieHiddenBits.Get(client)) {
			menu.SetTitle("Chat Bubbles\n \nYou send chat bubbles but can't see others\n ");
			menu.AddItem("off", "Hidden");
		} else {
			menu.SetTitle("Chat Bubbles\n \nYou see and send chat bubbles\n ");
			menu.AddItem("hide", "Enabled");
		}
	} else {
		menu.SetTitle("Chat Bubbles\n \nChat bubbles are complete disabled for you\n ");
		menu.AddItem("on", "Disabled");
	}
	menu.Pagination = MENU_NO_PAGINATION;
	menu.ExitButton = true;
	menu.Display(client, 30);
}

public int settingsMenuActionHandler(Menu menu, MenuAction action, int param1, int param2) {
	if(action == MenuAction_Select) {
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		if(StrEqual(info, "hide")) {
			cookieEnabledBits.Or(param1);
			cookieHiddenBits.Or(param1);
			if(cookie_ClientSetting != null) {
				SetClientCookie(param1, cookie_ClientSetting, "2");
			}
		} else if(StrEqual(info, "on")) {
			cookieEnabledBits.Or(param1);
			cookieHiddenBits.AndNot(param1);
			if(cookie_ClientSetting != null) {
				SetClientCookie(param1, cookie_ClientSetting, "1");
			}
		} else if(StrEqual(info, "off")) {
			cookieEnabledBits.AndNot(param1);
			cookieHiddenBits.Or(param1);
			if(cookie_ClientSetting != null) {
				SetClientCookie(param1, cookie_ClientSetting, "0");
			}
		}
		showSettingsMenu(param1);
	} else if(action == MenuAction_Cancel && param2 == MenuCancel_ExitBack) {
		ShowCookieMenu(param1);
	} else if(action == MenuAction_End) {
		delete menu;
	}
	return 0;
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	if (convar == null) {
		cval_BubbleEnabled = cvar_BubbleEnabled.IntValue;
		cval_BubbleDistance = cvar_BubbleDistance.FloatValue;
		cval_BubbleDefaultState = cvar_BubbleDefaultState.IntValue;
	} else if (convar == cvar_BubbleEnabled) {
		cval_BubbleEnabled = cvar_BubbleEnabled.IntValue;
	} else if (convar == cvar_BubbleDistance) {
		cval_BubbleDistance = cvar_BubbleDistance.FloatValue;
	} else if (convar == cvar_BubbleDefaultState) {
		cval_BubbleDefaultState = cvar_BubbleDefaultState.IntValue;
	}
}


/** 
 * Maintain team client masks
 */
public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId( event.GetInt("userid") );
	TFTeam team = view_as<TFTeam>( event.GetInt("team") );
	if (IsFakeClient(client)) return;
	
	switch (team) {
		case TFTeam_Red: {
			teamRedBits.Or(client);
			teamBlueBits.AndNot(client);
			aliveBits.Or(client);
		}
		case TFTeam_Blue: {
			teamRedBits.AndNot(client);
			teamBlueBits.Or(client);
			aliveBits.Or(client);
		}
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId( event.GetInt("userid") );
	
	aliveBits.AndNot(client);
}

public bool canSeeTraceFilter(int entity, int contentsMask, any data) {
	return entity == data;
}
static bool traceCanSee(int client, int target, float maxdistsquared) {
	if (!IsClientInGame(client) || !IsClientInGame(target) ||
		!IsPlayerAlive(client) || !IsPlayerAlive(target) ||
		IsFakeClient(client) || IsFakeClient(target)) {
		return false;
	}
	
	float posClient[3], posTarget[3], mins[3]={-14.0,0.0,-14.0}, maxs[3]={14.0,72.0,14.0};
	GetClientAbsOrigin(client, posClient);
	GetClientAbsOrigin(target, posTarget);
	float distance = GetVectorDistance(posClient, posTarget, true);
	if (distance > maxdistsquared) {
		return false;
	}
	
	// mins and maxs are only rough estimates, but that's ok
	Handle ray = TR_TraceHullFilterEx(posClient, posTarget, mins, maxs, MASK_VISIBLE, canSeeTraceFilter, target);
	bool result = TR_DidHit(ray);
	delete ray;
	return result;
}
static void updateClientMasks() {
	float mdist = cval_BubbleDistance*cval_BubbleDistance;
	for (int i=1; i<=MaxClients; i++) {
		for (int j=i+1; j<=MaxClients; j++) {
			
			bool canSee = traceCanSee(i,j, mdist);
			
			//perspecive i: i has not muted j and they can see each other
			canSeeBits[i].Set(j, canSee && !IsClientMuted(i,j));
			
			//perspecive j: j has not muted i and they can see each other
			canSeeBits[j].Set(i, canSee && !IsClientMuted(j,i));
			
		}
	}
}

static void bubble(int client, const char[] original, PlayerBits visibility) {
	//word wrap 50
	char message[MAX_ANNOTATION_LENGTH];
	strcopy(message, sizeof(message), original);
	TrimString(message);
	while (ReplaceString(message, sizeof(message), "  ", " ")) {/* collapse all multi-spaces */}
	//mark is the last space encountered to turn into a linebreak
	//accu is the amount of characters in the currently last line
	for (int i,mark,accu; message[i] && i<sizeof(message); i++) {
		if (message[i]==0)break;
		if (message[i]==' ')mark=i;
		else if (++accu >= 50 && mark) {
			message[mark] = '\n';
			accu = (i-mark);
			mark = 0;
		}
	}
	//find all "words" that are over 50 chars and break them
	wordBreakPattern.Match(message);
	char tmessage[MAX_ANNOTATION_LENGTH];
	char buffer[128];
	int cut, charsadded;
	while (wordBreakPattern.MatchCount()==1) {
		cut = wordBreakPattern.MatchOffset()+49; //find length of pre-match 1 "+0" (because we don't want to change capture 1')
		wordBreakPattern.GetSubString(0, buffer, sizeof(buffer));
		cut -= strlen(buffer); //we have to go back here, because MatchOffset returns the index AFTER the match
		while ((message[cut] & 0xC0)==0x80) cut++; //skip all utf8 continuations
		if (sizeof(tmessage) <= cut+2) break; //that'd be right at the end of the outbuffer, not worth tinkering there
		strcopy(tmessage, cut+1, message); //append left side
		tmessage[cut]='-';
		tmessage[cut+1]='\n'; //at the cut, we want a linebreak
		charsadded+=2;
		strcopy(tmessage[cut+2], sizeof(tmessage)-cut-2, message[cut]); //append right side
		strcopy(message, sizeof(message), tmessage); //copy back
		wordBreakPattern.Match(message, _, cut+2); //find more long spaghet
	}
	//put in an elipsis for messages that are somehow too long
	if (charsadded + strlen(message) >= MAX_ANNOTATION_LENGTH) {
		//fun fact: the horizontal elipsis character is 3 bytes as well
		cut = MAX_ANNOTATION_LENGTH-4;
		while (cut>0 && (message[cut] & 0xC0)==0x80) cut--; //seek back utf8 continuations
		message[MAX_ANNOTATION_LENGTH-4] = message[MAX_ANNOTATION_LENGTH-3] = message[MAX_ANNOTATION_LENGTH-2] = '.';
		message[MAX_ANNOTATION_LENGTH-1] = 0;
	}
	//diplay message
	CursorAnnotation ca = CursorAnnotation();
	for (int i=1; i<=MaxClients; i++) 
		ca.SetVisibilityFor(i, visibility.Get(i));
	ca.ParentEntity = client;
	float pos[3];
	GetClientAbsOrigin(client, pos);
	pos[2]+=72.0;
	ca.SetPosition(pos);
	ca.SetText(message);
	ca.SetLifetime(5.0);
	ca.AutoClose = true;
	ca.Update();
}

/** returns a tfteam if the client can chat with bubbles, or TFTeam_Unassigned if not */
static TFTeam clientBubbleTeam(int client, const char[] message) {
	// these strcontains calls are a "not starts with"
	if (!client || BaseComm_IsClientGagged(client) || !StrContains(message, "/") || !StrContains(message, "!") || !StrContains(message, "@"))
		return TFTeam_Unassigned;
	TFTeam team = view_as<TFTeam>( GetClientTeam(client) );
	if (team > TFTeam_Spectator) return team;
	return TFTeam_Unassigned;
}

static void handleSay(int client, const char[] message, bool teamSay) {
	TFTeam team = clientBubbleTeam(client, message);
	if (team <= TFTeam_Spectator) return;
	
	//check if player is invisible
	if (TF2_IsPlayerInCondition(client, TFCond_Cloaked)) return;
	
	PlayerBits targets;
	
	//if the player is disguised, play as say to not give away the actual team
	if (teamSay && !(TF2_IsPlayerInCondition(client, TFCond_Disguising)|TF2_IsPlayerInCondition(client, TFCond_Disguised)|TF2_IsPlayerInCondition(client, TFCond_DisguisedAsDispenser))) {
		//otherwise we mask the team for team say
		targets.OrBits((team==TFTeam_Red) ? teamRedBits : teamBlueBits);
	} else {
		targets.Not(); //default to all
	}
	
	//basic targets: alive, has them fully enabled, can see the source, not the source
	targets.AndBits(aliveBits);
	targets.AndNotBits(cookieHiddenBits);
	targets.AndBits(cookieEnabledBits);
	targets.AndBits(canSeeBits[client]);
	targets.AndNot(client);
	
	bubble(client, message, targets);
}

public Action commandSay(int client, const char[] command, int argc) {
#if defined _use_chatprocessor
	if (chatProcessorLoaded) return Plugin_Continue;
#endif
	if (cval_BubbleEnabled != 1 || !cookieEnabledBits.Get(client) ) return Plugin_Continue;
	char message[MAX_ANNOTATION_LENGTH];
	GetCmdArgString(message, sizeof(message));
	StripQuotes(message);
	if (!TrimString(message)) return Plugin_Continue;
	EscapeVGUILocalization(message, sizeof(message));
	handleSay(client, message, false);
	return Plugin_Continue;
}

public Action commandSayTeam(int client, const char[] command, int argc) {
#if defined _use_chatprocessor
	if (chatProcessorLoaded) return Plugin_Continue;
#endif
	if (cval_BubbleEnabled == 0 || !cookieEnabledBits.Get(client) ) return Plugin_Continue;
	char message[MAX_ANNOTATION_LENGTH];
	GetCmdArgString(message, sizeof(message));
	StripQuotes(message);
	if (!TrimString(message)) return Plugin_Continue;
	EscapeVGUILocalization(message, sizeof(message));
	handleSay(client, message, true);
	return Plugin_Continue;
}

#if defined _use_chatprocessor
static void anycp_OnChatPost(int author, ArrayList recipients, const char[] message) {
	TFTeam team = clientBubbleTeam(author, message);
	if (team <= TFTeam_Spectator) return;
	
	//check if player is invisible
	if (TF2_IsPlayerInCondition(author, TFCond_Cloaked)) return;
	
	PlayerBits targets;
	
	//for scp we can't use they team bypass for disguised spies!
	//accumulate targets into bit string
	for (int i; i<recipients.Length; i++) {
		targets.Or(recipients.Get(i));
	}
	
	//basic targets: alive, has them fully enabled, can see the source, not the source
	targets.AndBits(aliveBits);
	targets.AndNotBits(cookieHiddenBits);
	targets.AndBits(cookieEnabledBits);
	targets.AndBits(canSeeBits[author]);
	targets.AndNot(author);
	
	char smessage[MAX_ANNOTATION_LENGTH];
	strcopy(smessage, sizeof(smessage), message);
	EscapeVGUILocalization(smessage, sizeof(smessage));
	bubble(author, smessage, targets);
}
#endif

#if defined _scp_included
public void OnChatMessage_Post(int author, ArrayList recipients, const char[] name, const char[] message) {
	if (chatProcessorLoaded != CHAT_PROCESSOR_SCPREDUX) return;
	anycp_OnChatPost(author, recipients, message);
}
#endif

#if defined _CiderChatProcessor_included
public void CCP_OnChatMessagePost(int author, ArrayList recipients, const char[] flagstring, const char[] formatstring, const char[] name, const char[] message) {
	if (chatProcessorLoaded != CHAT_PROCESSOR_CIDER) return;
	anycp_OnChatPost(author, recipients, message);
}
#endif

#if defined _chat_processor_included
public void CP_OnChatMessagePost(int author, ArrayList recipients, const char[] flagstring, const char[] formatstring, const char[] name, const char[] message, bool processcolors, bool removecolors) {
	if (chatProcessorLoaded != CHAT_PROCESSOR_DRIXEVEL) return;
	anycp_OnChatPost(author, recipients, message);
}
#endif