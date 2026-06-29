/**     Description::
* This plugin slay the surviving players of the losing team at roundend.
* CT´s killed by the bomb will not loose hlstatsx points since they atleast tried,
*  everyone else slayed will do so at all other times.
**/
/*      Credits::
    Thanks to FlyingMongoose,  pimpinjuice & Bailopan for answering my questions ;)
        Also thanks to all people that posted plugins in the forum (too many to mention),
                they are great examples to learn from.
*/
/*      Console Variables::
        lts_enabled (Default 1)                 Turn on/off plugin.
        lts_minplayer (Default 3)       Minimum amount of players connected for the plugin to start slaying.
        lts_slaymsg (Default 1)         Tell the slayed people why they got slayed?
        lts_slay (Default 1)            Turn on/off slay (Warning only and no slay if lts_slaymsg = 1).
        lts_target_bombed               (Default "[LTS] Defuse the bomb or die trying!")
        lts_target_saved                        (Default "[LTS] Plant the bomb or die trying!")
        lts_bomb_defused                (Default "[LTS] Protect the bomb at all times!")
        lts_all_hostages_rescued        (Default "[LTS] Keep CT´s away from the hostages!")
        lts_hostages_not_rescued        (Default "[LTS] Rescue the hostages or die trying!")
*/
/*      Todo::
        Nothing planned.
*/
#include <sourcemod>
#define PLUGIN_VERSION "1.2.0.6"

new Handle:minplayer;
new Handle:slaymsg;
new Handle:enabled;
new Handle:slay;
new Handle:target_bombed;
new Handle:target_saved;
new Handle:bomb_defused;
new Handle:all_hostages_rescued;
new Handle:hostages_not_rescued;

public Plugin:myinfo =
{
        name = "Losing Team Slayer",
        author = "Lindgren, Bacardi",
        description = "Losing team get slayed at the end of the round :: Aka. Autoslay",
        version = PLUGIN_VERSION,
        url = "http://forums.alliedmods.net/showpost.php?p=1221481&postcount=22"
}

public OnPluginStart()
{
        // For tracking purpose
        CreateConVar("losingteamslay_version", PLUGIN_VERSION, "Current Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

        enabled = CreateConVar("lts_enabled", "1", "Enable/Disable plugin");
        minplayer = CreateConVar("lts_minplayer", "3", "Sets the minimum number of players needed to start plugin");
        slaymsg = CreateConVar("lts_slaymsg", "1", "If slayed player get chat msg telling him why he got slayed");
        slay = CreateConVar("lts_slay", "1", "Slay On/Off, Ie. warning only and no slay if lts_slaymsg = 1");

        HookEvent("round_end", Event_RoundEnd);
}

public OnMapStart()
{
        /* Reads and replaces the standard chat messages with custom text */
        target_bombed = CreateConVar("lts_target_bombed", "[LTS] Defuse the bomb or die trying!", "When the bomb detonate.");
        target_saved = CreateConVar("lts_target_saved", "[LTS] Plant the bomb or die trying!", "When the bomb dont get planted");
        bomb_defused = CreateConVar("lts_bomb_defused", "[LTS] Protect the bomb at all times!", "When the bomb is defused");
        all_hostages_rescued = CreateConVar("lts_all_hostages_rescued", "[LTS] Keep CT´s away from the hostages!", "When all hostages are rescued");
        hostages_not_rescued = CreateConVar("lts_hostages_not_rescued", "[LTS] Rescue the hostages or die trying!", "When hostages are NOT rescued");
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
        new reason = GetEventInt(event, "reason");
        new y = 0;
        for(new x = 1; x <= GetMaxClients(); ++x)
        {
                if(IsClientInGame(x))
                        y++;
        }
        if((y >= GetConVarInt(minplayer)) && (GetConVarInt(enabled) != 0))
                CreateTimer(0.2, Delayed_Slay, any:reason);
}

public Action:Delayed_Slay(Handle:timer, any:param)
{
        new winner;
        new String:message[100];

        // Teamwinner:: 2 = T, 3 = CT
        if (param == 0)
        {
                winner = 2;     // #Target_Bombed
                GetConVarString(target_bombed, message, sizeof(message));
        }
        if (param == 11)
        {
                winner = 3;     // #Target_Saved
                GetConVarString(target_saved, message, sizeof(message));
        }
        if (param == 6)
        {
                winner = 3;     // #Bomb_Defused
                GetConVarString(bomb_defused, message, sizeof(message));
        }
        if (param == 10)
        {
                winner = 3;     // #All_Hostages_Rescued
                GetConVarString(all_hostages_rescued, message, sizeof(message));
        }
        if (param == 12)
        {
                winner = 2;     // #Hostages_Not_Rescued
                GetConVarString(hostages_not_rescued, message, sizeof(message));
        }
        if (param == 7)
                winner =0;      // #CT_Win (All Terrorists killed)
        if (param == 8)
                winner = 0;     // #Terrorist_win (All Counter-Terrorists killed)
        if (param == 9)
                winner = 0;     // #Round_Draw
        if (param == 15)
                winner = 0;     // #Game_Commensing

        for(new i = 1; i <= GetMaxClients(); ++i)
        {
                if(IsClientInGame(i))
                {
                        new team = GetClientTeam(i);
                        new hp = GetEntData(i, FindSendPropOffs("CCSPlayer", "m_iHealth"));
                        if ((team != winner) && (team != 1) && (hp >= 1) && (winner != 0))
                        {
							if (GetConVarInt(slaymsg) != 0)
								PrintToChat(i, "%s", message);
                            if (GetConVarInt(slay) != 0)
								FakeClientCommand(i,"kill");								
                        }
                }
        }
}