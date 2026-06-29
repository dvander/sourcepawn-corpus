#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "Achievement Explain - TF2",
	author = "Oshroth",
	description = "Explains achievements in TF2",
	version = PLUGIN_VERSION,
	url = "<- URL ->"
}

public OnPluginStart()
{
	HookEvent("achievement_earned", Event_Achievement);
	CreateConVar("tf_achievement_explain_version", PLUGIN_VERSION, "Plugin version.", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CreateConVar("tf_achievement_explain_display", "1", "How to display messages. 1 - Chat, 2 - Hint, 0 - No Messages");
}

public Action:Event_Achievement(Handle:event, const String:name[], bool:dontBroadcast) {
	new id = GetEventInt(event, "achievement");
	decl String:ach[64];
	decl String:desc[256];
	new display = GetConVarInt(FindConVar("tf_achievement_explain_display"));
	
	if(display == 0) {
		return Plugin_Continue;
	}
	
	switch(id) {
		case 127: {
			strcopy(ach, sizeof(ach), "Sentry Gunner");
			strcopy(desc, sizeof(desc), "Accumulate 10 Sentry gun kills with a single turret");
		}
		case 128: {
			strcopy(ach, sizeof(ach), "Nemesis");
			strcopy(desc, sizeof(desc), "Get five Revenge kills");
		}
		case 129: {
			strcopy(ach, sizeof(ach), "Hard to Kill");
			strcopy(desc, sizeof(desc), "Get five kills in a row without dying");
		}
		case 130: {
			strcopy(ach, sizeof(ach), "Master of Disguise");
			strcopy(desc, sizeof(desc), "Trick an opposing Medic into healing you");
		}
		case 131: {
			strcopy(ach, sizeof(ach), "With Friends Like these...");
			strcopy(desc, sizeof(desc), "Play a game with 7 or more players from your friends list");
		}
		case 132: {
			strcopy(ach, sizeof(ach), "Dynasty");
			strcopy(desc, sizeof(desc), "Win 20 games");
		}
		case 133: {
			strcopy(ach, sizeof(ach), "Hardcore");
			strcopy(desc, sizeof(desc), "Accumulate 1000 total kills");
		}
		case 134: {
			strcopy(ach, sizeof(ach), "Powerhouse Offense");
			strcopy(desc, sizeof(desc), "Win 2Fort with a shutout");
		}
		case 135: {
			strcopy(ach, sizeof(ach), "Lightning Offense");
			strcopy(desc, sizeof(desc), "Win Well in 5 minutes or less");
		}
		case 136: {
			strcopy(ach, sizeof(ach), "Relentless Offense");
			strcopy(desc, sizeof(desc), "Win Hydro without giving up a capture");
		}
		case 137: {
			strcopy(ach, sizeof(ach), "Impenetrable Defense");
			strcopy(desc, sizeof(desc), "Successfully defend Dustbowl without giving up a capture");
		}
		case 138: {
			strcopy(ach, sizeof(ach), "Impossible Defense");
			strcopy(desc, sizeof(desc), "Successfully defend Gravel Pit without giving up a capture");
		}
		case 139: {
			strcopy(ach, sizeof(ach), "Head of the Class");
			strcopy(desc, sizeof(desc), "Play a complete round with every class");
		}
		case 140: {
			strcopy(ach, sizeof(ach), "World Traveler");
			strcopy(desc, sizeof(desc), "Play a complete game on 2Fort, Dustbowl, Granary, Gravel Pit, Hydro, and Well (CP)");
		}
		case 141: {
			strcopy(ach, sizeof(ach), "Team Doctor");
			strcopy(desc, sizeof(desc), "Accumulate 25000 heal points as a Medic");
		}
		case 142: {
			strcopy(ach, sizeof(ach), "Flamethrower");
			strcopy(desc, sizeof(desc), "Set five enemies on fire in 30 seconds");
		}
		case 145: {
			strcopy(ach, sizeof(ach), "Grey Matter");
			strcopy(desc, sizeof(desc), "Get 25 Headshots as a Sniper");
		}
		case 1001: {
			strcopy(ach, sizeof(ach), "First Blood");
			strcopy(desc, sizeof(desc), "Get the first kill in an Arena match");
		}
		case 1002: {
			strcopy(ach, sizeof(ach), "First Blood, Part 2");
			strcopy(desc, sizeof(desc), "Kill 5 enemies with the First Blood Crit buff");
		}
		case 1003: {
			strcopy(ach, sizeof(ach), "Quick Hook");
			strcopy(desc, sizeof(desc), "Kill a player in Well before the round starts");
		}
		case 1004: {
			strcopy(ach, sizeof(ach), "A Year to Remember");
			strcopy(desc, sizeof(desc), "Get 2004 lifetime kills");
		}
		case 1005: {
			strcopy(ach, sizeof(ach), "The Cycle");
			strcopy(desc, sizeof(desc), "In a single life, kill an enemy while you are on the ground, in the air, and in the water");
		}
		case 1006: {
			strcopy(ach, sizeof(ach), "Closer");
			strcopy(desc, sizeof(desc), "Destroy 3 teleporter entrances");
		}
		case 1007: {
			strcopy(ach, sizeof(ach), "If You Build It");
			strcopy(desc, sizeof(desc), "Destroy 3 enemy buildings while they are still under construction");
		}
		case 1008: {
			strcopy(ach, sizeof(ach), "Gun Down");
			strcopy(desc, sizeof(desc), "Destroy an active sentry gun using your pistol");
		}
		case 1009: {
			strcopy(ach, sizeof(ach), "Batter Up");
			strcopy(desc, sizeof(desc), "Perform 1000 double jumps");
		}
		case 1010: {
			strcopy(ach, sizeof(ach), "Doctoring the Ball");
			strcopy(desc, sizeof(desc), "Kill 3 enemies while under the effects of a Medic's ÜberCharge");
		}
		case 1011: {
			strcopy(ach, sizeof(ach), "Dodgers 1, Giants 0");
			strcopy(desc, sizeof(desc), "Kill an enemy Heavy and take his Sandvich");
		}
		case 1012: {
			strcopy(ach, sizeof(ach), "Batting the Doctor");
			strcopy(desc, sizeof(desc), "Kill a Medic that is ready to deploy an ÜberCharge");
		}
		case 1013: {
			strcopy(ach, sizeof(ach), "I'm Bat Man");
			strcopy(desc, sizeof(desc), "Survive 500 damage in one life");
		}
		case 1014: {
			strcopy(ach, sizeof(ach), "Triple Steal");
			strcopy(desc, sizeof(desc), "Capture the enemy intelligence 3 times in a single CTF round");
		}
		case 1015: {
			strcopy(ach, sizeof(ach), "Pop Fly");
			strcopy(desc, sizeof(desc), "Kill 20 players while double-jumping");
		}
		case 1016: {
			strcopy(ach, sizeof(ach), "Round Tripper");
			strcopy(desc, sizeof(desc), "Capture the enemy intelligence 25 times");
		}
		case 1017: {
			strcopy(ach, sizeof(ach), "Artful Dodger");
			strcopy(desc, sizeof(desc), "Dodge 1000 damage in a single life using your Bonk! Atomic Punch");
		}
		case 1018: {
			strcopy(ach, sizeof(ach), "Fall Classic");
			strcopy(desc, sizeof(desc), "Cause an environmental death or suicide using the Force-A-Nature's knockback");
		}
		case 1019: {
			strcopy(ach, sizeof(ach), "Strike Zone");
			strcopy(desc, sizeof(desc), "Kill 50 enemies while they are stunned");
		}
		case 1020: {
			strcopy(ach, sizeof(ach), "Foul Territory");
			strcopy(desc, sizeof(desc), "Cause an environmental death by stunning an enemy");
		}
		case 1021: {
			strcopy(ach, sizeof(ach), "The Big Hurt");
			strcopy(desc, sizeof(desc), "Stun 2 Medics that are ready to deploy an ÜberCharge");
		}
		case 1022: {
			strcopy(ach, sizeof(ach), "Brushback");
			strcopy(desc, sizeof(desc), "Stun 50 enemies while they are capturing a point or pushing the cart");
		}
		case 1023: {
			strcopy(ach, sizeof(ach), "Moon Shot");
			strcopy(desc, sizeof(desc), "Stun an enemy for the maximum possible duration by hitting them with a long-range ball");
		}
		case 1024: {
			strcopy(ach, sizeof(ach), "Beanball");
			strcopy(desc, sizeof(desc), "Stun a Scout with their own ball");
		}
		case 1025: {
			strcopy(ach, sizeof(ach), "Retire the Runner");
			strcopy(desc, sizeof(desc), "Kill a Scout while they are under the effect of Crit-a-Cola");
		}
		case 1026: {
			strcopy(ach, sizeof(ach), "Caught Napping");
			strcopy(desc, sizeof(desc), "Kill 50 enemies from behind with the Force-A-Nature");
		}
		case 1027: {
			strcopy(ach, sizeof(ach), "Side Retired");
			strcopy(desc, sizeof(desc), "Capture the last point in a CP map");
		}
		case 1028: {
			strcopy(ach, sizeof(ach), "Triple Play");
			strcopy(desc, sizeof(desc), "Capture three capture points in a row in one life");
		}
		case 1029: {
			strcopy(ach, sizeof(ach), "Stealing Home");
			strcopy(desc, sizeof(desc), "Start capping a capture point within a second of it becoming available");
		}
		case 1030: {
			strcopy(ach, sizeof(ach), "Set the Table");
			strcopy(desc, sizeof(desc), "Initiate 10 point captures that ultimately succeed");
		}
		case 1031: {
			strcopy(ach, sizeof(ach), "Block the Plate");
			strcopy(desc, sizeof(desc), "Block 50 point captures");
		}
		case 1032: {
			strcopy(ach, sizeof(ach), "Belittled Beleauger");
			strcopy(desc, sizeof(desc), "Kill an opposing player that has your intelligence while holding theirs");
		}
		case 1033: {
			strcopy(ach, sizeof(ach), "No Hitter");
			strcopy(desc, sizeof(desc), "Steal and then capture the enemy intelligence without firing a shot");
		}
		case 1034: {
			strcopy(ach, sizeof(ach), "Race for the Pennant");
			strcopy(desc, sizeof(desc), "Run 25 kilometers");
		}
		case 1035: {
			strcopy(ach, sizeof(ach), "Out of the Park");
			strcopy(desc, sizeof(desc), "Bat an enemy 25 meters");
		}
		case 1036: {
			strcopy(ach, sizeof(ach), "Scout Milestone 1");
			strcopy(desc, sizeof(desc), "Obtain 10 of the Scout achievements");
		}
		case 1037: {
			strcopy(ach, sizeof(ach), "Scout Milestone 2");
			strcopy(desc, sizeof(desc), "Obtain 16 of the Scout achievements");
		}
		case 1038: {
			strcopy(ach, sizeof(ach), "Scout Milestone 3");
			strcopy(desc, sizeof(desc), "Obtain 22 of the Scout achievements");
		}
		case 1101: {
			strcopy(ach, sizeof(ach), "Rode Hard, Put Away Wet");
			strcopy(desc, sizeof(desc), "Jarate an enemy that you're dominating");
		}
		case 1102: {
			strcopy(ach, sizeof(ach), "Be Polite");
			strcopy(desc, sizeof(desc), "Provide an enemy with a freezecam shot of you doffing your hat");
		}
		case 1103: {
			strcopy(ach, sizeof(ach), "Be Efficient");
			strcopy(desc, sizeof(desc), "Get 3 kills with the Sniper rifle without missing a shot");
		}
		case 1104: {
			strcopy(ach, sizeof(ach), "Have a Plan");
			strcopy(desc, sizeof(desc), "Capture the flag in CTF");
		}
		case 1105: {
			strcopy(ach, sizeof(ach), "Kill Everyone You Meet");
			strcopy(desc, sizeof(desc), "Kill 1000 enemies");
		}
		case 1106: {
			strcopy(ach, sizeof(ach), "Triple Prey");
			strcopy(desc, sizeof(desc), "In a single round, kill the same enemy with 3 different weapons");
		}
		case 1107: {
			strcopy(ach, sizeof(ach), "Self-destruct Sequence");
			strcopy(desc, sizeof(desc), "Headshot 10 enemy Snipers");
		}
		case 1108: {
			strcopy(ach, sizeof(ach), "De-sentry-lized");
			strcopy(desc, sizeof(desc), "Destroy 3 Engineer sentry guns");
		}
		case 1109: {
			strcopy(ach, sizeof(ach), "Shoot the Breeze");
			strcopy(desc, sizeof(desc), "Kill a fully invisible Spy in a single hit");
		}
		case 1110: {
			strcopy(ach, sizeof(ach), "Dropped Dead");
			strcopy(desc, sizeof(desc), "Kill a Scout in midair with your Sniper rifle or the Huntsman");
		}
		case 1111: {
			strcopy(ach, sizeof(ach), "The Last Wave");
			strcopy(desc, sizeof(desc), "Provide an enemy with a freezecam shot of you waving to them");
		}
		case 1112: {
			strcopy(ach, sizeof(ach), "Australian Rules");
			strcopy(desc, sizeof(desc), "Dominate an enemy Sniper");
		}
		case 1113: {
			strcopy(ach, sizeof(ach), "Kook the Spook");
			strcopy(desc, sizeof(desc), "Kill 10 Spies with your Kukri");
		}
		case 1114: {
			strcopy(ach, sizeof(ach), "Socket to Him");
			strcopy(desc, sizeof(desc), "Headshot an enemy Demoman");
		}
		case 1115: {
			strcopy(ach, sizeof(ach), "Jumper Stumper");
			strcopy(desc, sizeof(desc), "Kill a rocket or grenade-jumping enemy in midair with your Sniper rifle or the Huntsman");
		}
		case 1116: {
			strcopy(ach, sizeof(ach), "Not a Crazed Gunman, Dad");
			strcopy(desc, sizeof(desc), "In a single life, kill 3 enemies while they achieving an objective");
		}
		case 1117: {
			strcopy(ach, sizeof(ach), "Trust Your Feelings");
			strcopy(desc, sizeof(desc), "Get 5 kills with the Sniper rifle without your scope");
		}
		case 1118: {
			strcopy(ach, sizeof(ach), "Überectomy");
			strcopy(desc, sizeof(desc), "Kill a Medic that is ready to deploy an ÜberCharge");
		}
		case 1119: {
			strcopy(ach, sizeof(ach), "Consolation Prize");
			strcopy(desc, sizeof(desc), "Get backstabbed 50 times");
		}
		case 1120: {
			strcopy(ach, sizeof(ach), "Enemy at the Gate");
			strcopy(desc, sizeof(desc), "Kill an opponent within the first second of the round");
		}
		case 1121: {
			strcopy(ach, sizeof(ach), "Parting Shot");
			strcopy(desc, sizeof(desc), "Headshot an enemy player the moment his invulnerability wears off");
		}
		case 1122: {
			strcopy(ach, sizeof(ach), "My Brilliant Career");
			strcopy(desc, sizeof(desc), "Top the scoreboard 10 times on teams of 6 or more players");
		}
		case 1123: {
			strcopy(ach, sizeof(ach), "Shock Treatment");
			strcopy(desc, sizeof(desc), "Kill a Spy whose backstab attempt was blocked by your Razorback");
		}
		case 1124: {
			strcopy(ach, sizeof(ach), "Saturation Bombing");
			strcopy(desc, sizeof(desc), "Jarate 4 enemy players with a single throw");
		}
		case 1125: {
			strcopy(ach, sizeof(ach), "Rain on Their Parade");
			strcopy(desc, sizeof(desc), "Jarate an enemy and the Medic healing him");
		}
		case 1126: {
			strcopy(ach, sizeof(ach), "Jarring Transition");
			strcopy(desc, sizeof(desc), "Use Jarate to reveal a cloaked Spy");
		}
		case 1127: {
			strcopy(ach, sizeof(ach), "Friendship is Golden");
			strcopy(desc, sizeof(desc), "Extinguish a burning teammate with your Jarate");
		}
		case 1128: {
			strcopy(ach, sizeof(ach), "William Tell Overkill");
			strcopy(desc, sizeof(desc), "Pin an enemy Heavy to the wall via his head");
		}
		case 1129: {
			strcopy(ach, sizeof(ach), "Beaux and Arrows");
			strcopy(desc, sizeof(desc), "Kill a Heavy & Medic pair with the bow");
		}
		case 1130: {
			strcopy(ach, sizeof(ach), "Robbin’ Hood");
			strcopy(desc, sizeof(desc), "Take down an intelligence carrier with a single arrow");
		}
		case 1131: {
			strcopy(ach, sizeof(ach), "Pincushion");
			strcopy(desc, sizeof(desc), "Hit an enemy with 3 arrows, without killing them");
		}
		case 1132: {
			strcopy(ach, sizeof(ach), "Number One Assistant");
			strcopy(desc, sizeof(desc), "Score 5 Assists with the Jarate in a single round");
		}
		case 1133: {
			strcopy(ach, sizeof(ach), "Jarate Chop");
			strcopy(desc, sizeof(desc), "Use your Kukri to kill an enemy doused in your Jarate");
		}
		case 1134: {
			strcopy(ach, sizeof(ach), "Shafted");
			strcopy(desc, sizeof(desc), "Stab an enemy with an arrow");
		}
		case 1135: {
			strcopy(ach, sizeof(ach), "Dead Reckoning");
			strcopy(desc, sizeof(desc), "Kill an enemy with an arrow while you're dead");
		}
		case 1136: {
			strcopy(ach, sizeof(ach), "Sniper Milestone 1");
			strcopy(desc, sizeof(desc), "Obtain 5 of the Sniper achievements");
		}
		case 1137: {
			strcopy(ach, sizeof(ach), "Sniper Milestone 2");
			strcopy(desc, sizeof(desc), "Obtain 11 of the Sniper achievements");
		}
		case 1138: {
			strcopy(ach, sizeof(ach), "Sniper Milestone 3");
			strcopy(desc, sizeof(desc), "Obtain 17 of the Sniper achievements");
		}
		case 1201: {
			strcopy(ach, sizeof(ach), "Duty Bound");
			strcopy(desc, sizeof(desc), "While rocket jumping kill an enemy with the Equalizer before you land");
		}
		case 1202: {
			strcopy(ach, sizeof(ach), "The Boostie Boys");
			strcopy(desc, sizeof(desc), "Buff 15 teammates with the Buff Banner in a single life");
		}
		case 1203: {
			strcopy(ach, sizeof(ach), "Out, Damned Scot!");
			strcopy(desc, sizeof(desc), "Kill 500 enemy Demomen");
		}
		case 1204: {
			strcopy(ach, sizeof(ach), "Engineer to Eternity");
			strcopy(desc, sizeof(desc), "Kill an Engineer as he repairs his sentry gun while it's under enemy fire");
		}
		case 1205: {
			strcopy(ach, sizeof(ach), "Backdraft Dodger");
			strcopy(desc, sizeof(desc), "Kill a Pyro who has airblasted one of your rockets in the last 10 seconds");
		}
		case 1206: {
			strcopy(ach, sizeof(ach), "Trench Warfare");
			strcopy(desc, sizeof(desc), "Kill your nemesis with a shovel");
		}
		case 1207: {
			strcopy(ach, sizeof(ach), "Bomb Squaddie");
			strcopy(desc, sizeof(desc), "Destroy 10 sticky bombs with the shotgun in a single life");
		}
		case 1208: {
			strcopy(ach, sizeof(ach), "Where Eagles Dare");
			strcopy(desc, sizeof(desc), "Get the highest possible rocket jump using jump and crouch");
		}
		case 1209: {
			strcopy(ach, sizeof(ach), "Ain't Got Time to Bleed");
			strcopy(desc, sizeof(desc), "Kill 3 players with the Equalizer in a single life without being healed");
		}
		case 1210: {
			strcopy(ach, sizeof(ach), "Banner of Brothers");
			strcopy(desc, sizeof(desc), "Buff 5 steam friends at once with the Buff Banner");
		}
		case 1211: {
			strcopy(ach, sizeof(ach), "Tri-Splatteral Damage");
			strcopy(desc, sizeof(desc), "Kill 3 enemies with a single Critical rocket");
		}
		case 1212: {
			strcopy(ach, sizeof(ach), "Death from Above");
			strcopy(desc, sizeof(desc), "Rocket jump and kill 2 enemies before you land");
		}
		case 1213: {
			strcopy(ach, sizeof(ach), "Spray of Defeat");
			strcopy(desc, sizeof(desc), "Use a grenade to gib a player");
		}
		case 1214: {
			strcopy(ach, sizeof(ach), "War Crime and Punishment");
			strcopy(desc, sizeof(desc), "In a single life, kill 3 enemies who have damaged a Medic that is healing you");
		}
		case 1215: {
			strcopy(ach, sizeof(ach), "Near Death Experience");
			strcopy(desc, sizeof(desc), "Kill 20 enemies with your Equalizer while you have less than 25 health");
		}
		case 1216: {
			strcopy(ach, sizeof(ach), "Wings of Glory");
			strcopy(desc, sizeof(desc), "Kill an enemy Soldier while both you and the target are airborne");
		}
		case 1217: {
			strcopy(ach, sizeof(ach), "For Whom the Shell Trolls");
			strcopy(desc, sizeof(desc), "Bounce an opponent into the air with a rocket and then kill them with the shotgun before they land");
		}
		case 1218: {
			strcopy(ach, sizeof(ach), "Death From Below");
			strcopy(desc, sizeof(desc), "Kill 10 opponents who are airborne with the Direct hit");
		}
		case 1219: {
			strcopy(ach, sizeof(ach), "Mutually Assured Destruction");
			strcopy(desc, sizeof(desc), "Kill an enemy sniper with a rocket after he kills you");
		}
		case 1220: {
			strcopy(ach, sizeof(ach), "Guns of the Navar0wned");
			strcopy(desc, sizeof(desc), "Kill 5 Engineer sentries while you are standing outside of their range");
		}
		case 1221: {
			strcopy(ach, sizeof(ach), "Brothers in Harms");
			strcopy(desc, sizeof(desc), "Kill 10 enemies while assisting or being assisted by another Soldier");
		}
		case 1222: {
			strcopy(ach, sizeof(ach), "Medals of Honor");
			strcopy(desc, sizeof(desc), "Finish a round as an MVP on a team of 6 or more players 10 times");
		}
		case 1223: {
			strcopy(ach, sizeof(ach), "S*M*A*S*H");
			strcopy(desc, sizeof(desc), "Assist a Medic in exploding 5 enemies with a single ÜberCharge");
		}
		case 1224: {
			strcopy(ach, sizeof(ach), "Crockets Are Such B.S.");
			strcopy(desc, sizeof(desc), "Shoot two non-boosted Crit rockets in a row");
		}
		case 1225: {
			strcopy(ach, sizeof(ach), "Geneva Contravention");
			strcopy(desc, sizeof(desc), "Kill 5 defenseless players after a single match has ended");
		}
		case 1226: {
			strcopy(ach, sizeof(ach), "Semper Fry");
			strcopy(desc, sizeof(desc), "Kill 20 enemies while you are on fire");
		}
		case 1227: {
			strcopy(ach, sizeof(ach), "Worth a Thousand Words");
			strcopy(desc, sizeof(desc), "Provide the enemy with a freezecam of your 21 gun salute");
		}
		case 1228: {
			strcopy(ach, sizeof(ach), "Gore-a! Gore-a! Gore-a!");
			strcopy(desc, sizeof(desc), "Provide the enemy with a freezecam of you taunting over 3 of their body parts");
		}
		case 1229: {
			strcopy(ach, sizeof(ach), "War Crime Spybunal");
			strcopy(desc, sizeof(desc), "Kill a Spy who just backstabbed a teammate");
		}
		case 1230: {
			strcopy(ach, sizeof(ach), "Frags of our Fathers");
			strcopy(desc, sizeof(desc), "Gib 1000 people");
		}
		case 1231: {
			strcopy(ach, sizeof(ach), "Dominator");
			strcopy(desc, sizeof(desc), "Get 3 dominations in a single life");
		}
		case 1232: {
			strcopy(ach, sizeof(ach), "Ride of the Valkartie");
			strcopy(desc, sizeof(desc), "Ride the cart for 30 seconds");
		}
		case 1233: {
			strcopy(ach, sizeof(ach), "Screamin' Eagle");
			strcopy(desc, sizeof(desc), "Kill 20 enemies from above");
		}
		case 1234: {
			strcopy(ach, sizeof(ach), "The Longest Daze");
			strcopy(desc, sizeof(desc), "Kill 5 stunned players");
		}
		case 1235: {
			strcopy(ach, sizeof(ach), "Hamburger Hill");
			strcopy(desc, sizeof(desc), "Defend a cap point 30 times");
		}
		case 1236: {
			strcopy(ach, sizeof(ach), "Soldier Milestone 1");
			strcopy(desc, sizeof(desc), "Obtain 5 of the Soldier achievements");
		}
		case 1237: {
			strcopy(ach, sizeof(ach), "Soldier Milestone 2");
			strcopy(desc, sizeof(desc), "Obtain 11 of the Soldier achievements");
		}
		case 1238: {
			strcopy(ach, sizeof(ach), "Soldier Milestone 3");
			strcopy(desc, sizeof(desc), "Obtain 17 of the Soldier achievements");
		}
		case 1301: {
			strcopy(ach, sizeof(ach), "Kilt in Action");
			strcopy(desc, sizeof(desc), "Kill 500 enemy Soldiers");
		}
		case 1302: {
			strcopy(ach, sizeof(ach), "Tam O'Shatter");
			strcopy(desc, sizeof(desc), "Destroy 5 enemy Engineer buildings during a single ÜberCharge from a Medic");
		}
		case 1303: {
			strcopy(ach, sizeof(ach), "Shorn Connery");
			strcopy(desc, sizeof(desc), "Decapitate a cloaked Spy");
		}
		case 1304: {
			strcopy(ach, sizeof(ach), "Laddy Macdeth");
			strcopy(desc, sizeof(desc), "Kill 50 enemies with direct hits from the Grenade Launcher");
		}
		case 1305: {
			strcopy(ach, sizeof(ach), "Caber Toss");
			strcopy(desc, sizeof(desc), "Bounce an enemy into the air and kill them before they land");
		}
		case 1306: {
			strcopy(ach, sizeof(ach), "Double Mauled Scotch");
			strcopy(desc, sizeof(desc), "Kill 2 people in a single sticky jump");
		}
		case 1307: {
			strcopy(ach, sizeof(ach), "Loch Ness Bombster");
			strcopy(desc, sizeof(desc), "Kill an enemy player with sticky bombs within 5 seconds of them teleporting");
		}
		case 1308: {
			strcopy(ach, sizeof(ach), "Three Times a Laddy");
			strcopy(desc, sizeof(desc), "Dominate three Engineers");
		}
		case 1309: {
			strcopy(ach, sizeof(ach), "Blind Fire");
			strcopy(desc, sizeof(desc), "Destroy an Engineer building that you can't see with a direct hit from your Grenade Launcher");
		}
		case 1310: {
			strcopy(ach, sizeof(ach), "Brainspotting");
			strcopy(desc, sizeof(desc), "Decapitate 50 enemy players");
		}
		case 1311: {
			strcopy(ach, sizeof(ach), "Left 4 Heads");
			strcopy(desc, sizeof(desc), "Decapitate 4 players with only 10 seconds between each kill");
		}
		case 1312: {
			strcopy(ach, sizeof(ach), "Well Plaid!");
			strcopy(desc, sizeof(desc), "Kill 10 enemies while assisting or being assisted by another Demoman");
		}
		case 1313: {
			strcopy(ach, sizeof(ach), "The Scottish Play");
			strcopy(desc, sizeof(desc), "Get a melee kill while sticky jumping");
		}
		case 1314: {
			strcopy(ach, sizeof(ach), "The Argyle Sap");
			strcopy(desc, sizeof(desc), "Blow up an Engineer, his sentry gun, and his dispenser with a single Sticky bomb detonation");
		}
		case 1315: {
			strcopy(ach, sizeof(ach), "Slammy Slayvis Woundya");
			strcopy(desc, sizeof(desc), "Decapitate an enemy Soldier who is brandishing the Equalizer");
		}
		case 1316: {
			strcopy(ach, sizeof(ach), "There Can Be Only One");
			strcopy(desc, sizeof(desc), "Decapitate your nemesis");
		}
		case 1317: {
			strcopy(ach, sizeof(ach), "Tartan Spartan");
			strcopy(desc, sizeof(desc), "Do 1 million points of total blast damage");
		}
		case 1318: {
			strcopy(ach, sizeof(ach), "Scotch Guard");
			strcopy(desc, sizeof(desc), "Kill 3 enemies capping or pushing a cart in a single Stickybomb detonation 3 separate times");
		}
		case 1319: {
			strcopy(ach, sizeof(ach), "Bravehurt");
			strcopy(desc, sizeof(desc), "Kill 25 players defending a capture point or cart");
		}
		case 1320: {
			strcopy(ach, sizeof(ach), "Cry Some Moor!");
			strcopy(desc, sizeof(desc), "Destroy 50 buildings");
		}
		case 1321: {
			strcopy(ach, sizeof(ach), "The Stickening");
			strcopy(desc, sizeof(desc), "Kill 5 Heavies from full health with a single sticky bomb detonation");
		}
		case 1322: {
			strcopy(ach, sizeof(ach), "Glasg0wned");
			strcopy(desc, sizeof(desc), "Kill 25 Scouts and Pyros with the Grenade Launcher");
		}
		case 1323: {
			strcopy(ach, sizeof(ach), "Scotch Tap");
			strcopy(desc, sizeof(desc), "Glory in the slaughter of your enemies using the Eyelander");
		}
		case 1324: {
			strcopy(ach, sizeof(ach), "The Targe Charge");
			strcopy(desc, sizeof(desc), "Charge and kill someone with your shield bash");
		}
		case 1325: {
			strcopy(ach, sizeof(ach), "Beat Me Up, Scotty");
			strcopy(desc, sizeof(desc), "Use a full charge Critical swing with the Eyelander to kill 5 enemy players");
		}
		case 1326: {
			strcopy(ach, sizeof(ach), "Something Stickied This Way Comes");
			strcopy(desc, sizeof(desc), "Kill 30 players with air burst sticky bombs");
		}
		case 1327: {
			strcopy(ach, sizeof(ach), "The High Road");
			strcopy(desc, sizeof(desc), "Sticky jump onto a cap point and capture it");
		}
		case 1328: {
			strcopy(ach, sizeof(ach), "Bloody Merry");
			strcopy(desc, sizeof(desc), "Provide an enemy player with a freeze cam of your smiling face");
		}
		case 1329: {
			strcopy(ach, sizeof(ach), "Second Eye");
			strcopy(desc, sizeof(desc), "Provide an enemy player with a freeze cam of you shaking your rump");
		}
		case 1330: {
			strcopy(ach, sizeof(ach), "He Who Celt It");
			strcopy(desc, sizeof(desc), "Use the Sticky Launcher to kill an enemy player via environmental damage");
		}
		case 1331: {
			strcopy(ach, sizeof(ach), "Robbed Royal");
			strcopy(desc, sizeof(desc), "Destroy 100 sticky bombs with the Scottish Resistance");
		}
		case 1332: {
			strcopy(ach, sizeof(ach), "Highland Fling");
			strcopy(desc, sizeof(desc), "Sticky jump a really long way..");
		}
		case 1333: {
			strcopy(ach, sizeof(ach), "Pipebagger");
			strcopy(desc, sizeof(desc), "Kill at least three players with a single detonation of sticky bombs");
		}
		case 1334: {
			strcopy(ach, sizeof(ach), "Spynal Tap");
			strcopy(desc, sizeof(desc), "Kill 20 Spies within 5 seconds of them sapping a friendly building");
		}
		case 1335: {
			strcopy(ach, sizeof(ach), "Sticky Thump");
			strcopy(desc, sizeof(desc), "Using the Scottish Resistance, kill 3 players in separate explosions without placing new sticky bombs");
		}
		case 1336: {
			strcopy(ach, sizeof(ach), "Demoman Milestone 1");
			strcopy(desc, sizeof(desc), "Obtain 5 of the Demoman achievements");
		}
		case 1337: {
			strcopy(ach, sizeof(ach), "Demoman Milestone 2");
			strcopy(desc, sizeof(desc), "Obtain 11 of the Demoman achievements");
		}
		case 1338: {
			strcopy(ach, sizeof(ach), "Demoman Milestone 3");
			strcopy(desc, sizeof(desc), "Obtain 17 of the Demoman achievements");
		}
		case 1401: {
			strcopy(ach, sizeof(ach), "First Do No Harm");
			strcopy(desc, sizeof(desc), "Play a full round without killing any enemies and score the highest on a team of six or more players");
		}
		case 1402: {
			strcopy(ach, sizeof(ach), "Quadruple Bypass");
			strcopy(desc, sizeof(desc), "Heal a teammate who is taking fire from four enemies at once");
		}
		case 1403: {
			strcopy(ach, sizeof(ach), "Group Health");
			strcopy(desc, sizeof(desc), "Work with two other Medics to deploy three simultaneous ÜberCharges");
		}
		case 1404: {
			strcopy(ach, sizeof(ach), "Surgical Prep");
			strcopy(desc, sizeof(desc), "Have an ÜberCharge ready before the set up phase ends");
		}
		case 1405: {
			strcopy(ach, sizeof(ach), "Trauma Queen");
			strcopy(desc, sizeof(desc), "Deploy three ÜberCharges in less than five minutes and assist in five kills during that time");
		}
		case 1406: {
			strcopy(ach, sizeof(ach), "Double Blind Trial");
			strcopy(desc, sizeof(desc), "Deploy an ÜberCharge within eight seconds of a nearby enemy Medic deploying his");
		}
		case 1407: {
			strcopy(ach, sizeof(ach), "Play Doctor");
			strcopy(desc, sizeof(desc), "In a team with no Medics, be first to switch to Medic after a teammate calls Medic and heal 500 health");
		}
		case 1408: {
			strcopy(ach, sizeof(ach), "Triage");
			strcopy(desc, sizeof(desc), "Deploy an ÜberCharge on a teammate less than a second before they are hit by a Critical explosive");
		}
		case 1409: {
			strcopy(ach, sizeof(ach), "Preventative Medicine");
			strcopy(desc, sizeof(desc), "Block the enemy from capturing a control point with an ÜberCharged teammate");
		}
		case 1410: {
			strcopy(ach, sizeof(ach), "Consultation");
			strcopy(desc, sizeof(desc), "Assist a fellow Medic in killing five enemies in a single life");
		}
		case 1411: {
			strcopy(ach, sizeof(ach), "Does It Hurt When I Do This?");
			strcopy(desc, sizeof(desc), "Kill fifty Scouts with your syringe gun");
		}
		case 1412: {
			strcopy(ach, sizeof(ach), "Peer Review");
			strcopy(desc, sizeof(desc), "Kill fifty Medics with your bone saw");
		}
		case 1413: {
			strcopy(ach, sizeof(ach), "Big Pharma");
			strcopy(desc, sizeof(desc), "Assist a Heavy in killing ten enemies where neither of you die");
		}
		case 1414: {
			strcopy(ach, sizeof(ach), "You'll Feel a Little Prick");
			strcopy(desc, sizeof(desc), "Assist in killing three enemies with a single ÜberCharge on a Scout");
		}
		case 1415: {
			strcopy(ach, sizeof(ach), "Autoclave");
			strcopy(desc, sizeof(desc), "Assist in burning five enemies with a single ÜberCharge on a Pyro");
		}
		case 1416: {
			strcopy(ach, sizeof(ach), "Blunt Trauma");
			strcopy(desc, sizeof(desc), "Assist in punching two enemies with a single ÜberCharge on a Heavy");
		}
		case 1417: {
			strcopy(ach, sizeof(ach), "Medical Breakthrough");
			strcopy(desc, sizeof(desc), "Assist in destroying five enemy Engineer buildings with a single ÜberCharge on a Demoman");
		}
		case 1418: {
			strcopy(ach, sizeof(ach), "Blast Assist");
			strcopy(desc, sizeof(desc), "Assist in exploding five enemies with a single ÜberCharge on a Soldier");
		}
		case 1419: {
			strcopy(ach, sizeof(ach), "Midwife Crisis");
			strcopy(desc, sizeof(desc), "Heal an Engineer as he repairs his sentry gun while it's under enemy fire");
		}
		case 1420: {
			strcopy(ach, sizeof(ach), "Ubi Concordia, Ibi Victoria");
			strcopy(desc, sizeof(desc), "Assist in killing three enemies on an enemy control point in a single life");
		}
		case 1421: {
			strcopy(ach, sizeof(ach), "Grand Rounds");
			strcopy(desc, sizeof(desc), "Heal two hundred teammates after they have called for Medic");
		}
		case 1422: {
			strcopy(ach, sizeof(ach), "Infernal Medicine");
			strcopy(desc, sizeof(desc), "Extinguish one hundred burning teammates");
		}
		case 1423: {
			strcopy(ach, sizeof(ach), "Doctor Assisted Homicide");
			strcopy(desc, sizeof(desc), "Assist in killing twenty nemeses");
		}
		case 1424: {
			strcopy(ach, sizeof(ach), "Placebo Effect");
			strcopy(desc, sizeof(desc), "Kill five enemies in a single life, while having your ÜberCharge ready but undeployed");
		}
		case 1425: {
			strcopy(ach, sizeof(ach), "Sawbones");
			strcopy(desc, sizeof(desc), "Hit enemies with your bonesaw five times in a row without dying or missing");
		}
		case 1426: {
			strcopy(ach, sizeof(ach), "Intern");
			strcopy(desc, sizeof(desc), "Accumulate seven thousand heal points in a single life");
		}
		case 1427: {
			strcopy(ach, sizeof(ach), "Specialist");
			strcopy(desc, sizeof(desc), "Accumulate ten thousand heal points in a single life");
		}
		case 1428: {
			strcopy(ach, sizeof(ach), "Chief of Staff");
			strcopy(desc, sizeof(desc), "Accumulate one million total health points");
		}
		case 1429: {
			strcopy(ach, sizeof(ach), "Hypocritical Oath");
			strcopy(desc, sizeof(desc), "Kill an enemy Spy that you have been healing");
		}
		case 1430: {
			strcopy(ach, sizeof(ach), "Medical Intervention");
			strcopy(desc, sizeof(desc), "Save a falling teammate from dying on impact");
		}
		case 1431: {
			strcopy(ach, sizeof(ach), "Second Opinion");
			strcopy(desc, sizeof(desc), "ÜberCharge 2 teammates at once");
		}
		case 1432: {
			strcopy(ach, sizeof(ach), "Autopsy Report");
			strcopy(desc, sizeof(desc), "Provide an enemy with a freezecam shot of you taunting above their ragdoll");
		}
		case 1433: {
			strcopy(ach, sizeof(ach), "FYI I am a Medic");
			strcopy(desc, sizeof(desc), "Use a bonesaw to kill five enemy Spies who have been calling for Medic");
		}
		case 1434: {
			strcopy(ach, sizeof(ach), "Family Practice");
			strcopy(desc, sizeof(desc), "ÜberCharge ten of your steam community friends");
		}
		case 1435: {
			strcopy(ach, sizeof(ach), "House Call");
			strcopy(desc, sizeof(desc), "Join a game that one of your friends is in and then deploy an ÜberCharge on him");
		}
		case 1436: {
			strcopy(ach, sizeof(ach), "Bedside Manner");
			strcopy(desc, sizeof(desc), "Be healing a teammate as he achieves an achievement of his own");
		}
		case 1437: {
			strcopy(ach, sizeof(ach), "Medic Milestone 1");
			strcopy(desc, sizeof(desc), "Obtain 10 of the Medic achievements");
		}
		case 1438: {
			strcopy(ach, sizeof(ach), "Medic Milestone 2");
			strcopy(desc, sizeof(desc), "Obtain 16 of the Medic achievements");
		}
		case 1439: {
			strcopy(ach, sizeof(ach), "Medic Milestone 3");
			strcopy(desc, sizeof(desc), "Obtain 22 of the Medic achievements");
		}
		case 1501: {
			strcopy(ach, sizeof(ach), "Iron Kurtain");
			strcopy(desc, sizeof(desc), "Take 1000 points of damage in a single life");
		}
		case 1502: {
			strcopy(ach, sizeof(ach), "Party Loyalty");
			strcopy(desc, sizeof(desc), "Kill 50 enemies within 3 seconds of them attacking your Medic");
		}
		case 1503: {
			strcopy(ach, sizeof(ach), "Division of Labor");
			strcopy(desc, sizeof(desc), "Kill 10 enemies with a Medic assisting you, where neither of you die");
		}
		case 1504: {
			strcopy(ach, sizeof(ach), "Red Oktoberfest");
			strcopy(desc, sizeof(desc), "Earn a domination for a Medic who's healing you");
		}
		case 1505: {
			strcopy(ach, sizeof(ach), "Show Trial");
			strcopy(desc, sizeof(desc), "Kill an enemy with a taunt");
		}
		case 1506: {
			strcopy(ach, sizeof(ach), "Crime and Punishment");
			strcopy(desc, sizeof(desc), "Kill 10 enemies carrying your intelligence");
		}
		case 1507: {
			strcopy(ach, sizeof(ach), "Class Struggle");
			strcopy(desc, sizeof(desc), "Work with a friendly Medic to kill an enemy Heavy Medic pair");
		}
		case 1508: {
			strcopy(ach, sizeof(ach), "Soviet Block");
			strcopy(desc, sizeof(desc), "While invulnerable and on defense, block an invulnerable enemy Heavy's movement");
		}
		case 1509: {
			strcopy(ach, sizeof(ach), "Stalin the Kart");
			strcopy(desc, sizeof(desc), "Block the enemy from moving the payload cart 25 times");
		}
		case 1510: {
			strcopy(ach, sizeof(ach), "Supreme Soviet");
			strcopy(desc, sizeof(desc), "Get Übered 50 times");
		}
		case 1511: {
			strcopy(ach, sizeof(ach), "Factory Worker");
			strcopy(desc, sizeof(desc), "Kill 20 enemies while being recharged by a dispenser");
		}
		case 1512: {
			strcopy(ach, sizeof(ach), "Soviet Union");
			strcopy(desc, sizeof(desc), "Get 25 enemy kills where you either assist or are assisted by another Heavy");
		}
		case 1513: {
			strcopy(ach, sizeof(ach), "Own the Means of Production");
			strcopy(desc, sizeof(desc), "Remove 20 stickybombs by killing the Demomen who produced them");
		}
		case 1514: {
			strcopy(ach, sizeof(ach), "Krazy Ivan");
			strcopy(desc, sizeof(desc), "Kill 100 enemies while both you and your victim are underwater");
		}
		case 1515: {
			strcopy(ach, sizeof(ach), "Rasputin");
			strcopy(desc, sizeof(desc), "In a single life, get shot, burned, bludgeoned, and receive explosive damage");
		}
		case 1516: {
			strcopy(ach, sizeof(ach), "Icing on the Cake");
			strcopy(desc, sizeof(desc), "Get 20 kills on players that you're dominating");
		}
		case 1517: {
			strcopy(ach, sizeof(ach), "Crock Block");
			strcopy(desc, sizeof(desc), "Survive a direct hit from a Critical rocket");
		}
		case 1518: {
			strcopy(ach, sizeof(ach), "Kollectivization");
			strcopy(desc, sizeof(desc), "Get 1000 assists");
		}
		case 1519: {
			strcopy(ach, sizeof(ach), "Spyalectical Materialism");
			strcopy(desc, sizeof(desc), "Kill or assist in killing 10 cloaked Spies");
		}
		case 1520: {
			strcopy(ach, sizeof(ach), "Permanent Revolution");
			strcopy(desc, sizeof(desc), "Kill 5 enemies without spinning down your gun");
		}
		case 1521: {
			strcopy(ach, sizeof(ach), "Heavy Industry");
			strcopy(desc, sizeof(desc), "Fire $200,000 worth of minigun rounds in a single life");
		}
		case 1522: {
			strcopy(ach, sizeof(ach), "Communist Mani-Fisto");
			strcopy(desc, sizeof(desc), "Kill an enemy with a Critical punch");
		}
		case 1523: {
			strcopy(ach, sizeof(ach), "Redistribution of Health");
			strcopy(desc, sizeof(desc), "Heal 1000 damage with med-kits in a single life");
		}
		case 1524: {
			strcopy(ach, sizeof(ach), "Rationing");
			strcopy(desc, sizeof(desc), "Kill an enemy with your shotgun while you're out of minigun ammo");
		}
		case 1525: {
			strcopy(ach, sizeof(ach), "Vanguard Party");
			strcopy(desc, sizeof(desc), "Be the first on your team to start capturing a control point in a round");
		}
		case 1527: {
			strcopy(ach, sizeof(ach), "Pushkin the Kart");
			strcopy(desc, sizeof(desc), "Get 50 caps on payload maps");
		}
		case 1528: {
			strcopy(ach, sizeof(ach), "Marxman");
			strcopy(desc, sizeof(desc), "Kill 10 enemies in mid-air with the minigun");
		}
		case 1529: {
			strcopy(ach, sizeof(ach), "Gorky Parked");
			strcopy(desc, sizeof(desc), "Kill 25 enemies while you're standing on a control point you own");
		}
		case 1530: {
			strcopy(ach, sizeof(ach), "Purge");
			strcopy(desc, sizeof(desc), "Kill 15 enemies capturing a control point you own");
		}
		case 1531: {
			strcopy(ach, sizeof(ach), "Lenin A Hand");
			strcopy(desc, sizeof(desc), "Help 5 team-mates get revenge on their nemeses");
		}
		case 1532: {
			strcopy(ach, sizeof(ach), "Five Second Plan");
			strcopy(desc, sizeof(desc), "Kill an enemy in the first 5 seconds after you exit a teleporter");
		}
		case 1533: {
			strcopy(ach, sizeof(ach), "Photostroika");
			strcopy(desc, sizeof(desc), "Provide an enemy with a freezecam shot of you taunting while invulnerable");
		}
		case 1534: {
			strcopy(ach, sizeof(ach), "Konspicuous Konsumption");
			strcopy(desc, sizeof(desc), "Eat 100 sandviches");
		}
		case 1535: {
			strcopy(ach, sizeof(ach), "Don't Touch Sandvich");
			strcopy(desc, sizeof(desc), "Kill 50 Scouts using Natascha");
		}
		case 1536: {
			strcopy(ach, sizeof(ach), "Borscht Belt");
			strcopy(desc, sizeof(desc), "Kill 10 Heavies with The K.G.B");
		}
		case 1537: {
			strcopy(ach, sizeof(ach), "Heavy Milestone 1");
			strcopy(desc, sizeof(desc), "Obtain 10 of the Heavy achievements");
		}
		case 1538: {
			strcopy(ach, sizeof(ach), "Heavy Milestone 2");
			strcopy(desc, sizeof(desc), "Obtain 15 of the Heavy achievements");
		}
		case 1539: {
			strcopy(ach, sizeof(ach), "Heavy Milestone 3");
			strcopy(desc, sizeof(desc), "Obtain 20 of the Heavy achievements");
		}
		case 1601: {
			strcopy(ach, sizeof(ach), "Combined Fire");
			strcopy(desc, sizeof(desc), "Use your shotgun to finish off 20 players you've ignited");
		}
		case 1602: {
			strcopy(ach, sizeof(ach), "Weenie Roast");
			strcopy(desc, sizeof(desc), "Assist in killing five enemies on an enemy control point in a single life");
		}
		case 1603: {
			strcopy(ach, sizeof(ach), "Baptism by Fire");
			strcopy(desc, sizeof(desc), "Force 10 burning enemies to jump into water");
		}
		case 1604: {
			strcopy(ach, sizeof(ach), "Fire and Forget");
			strcopy(desc, sizeof(desc), "Kill 15 players while you're dead");
		}
		case 1605: {
			strcopy(ach, sizeof(ach), "Firewall");
			strcopy(desc, sizeof(desc), "Ignite 5 Spies who have a sapper on a friendly building");
		}
		case 1606: {
			strcopy(ach, sizeof(ach), "Cooking the Books");
			strcopy(desc, sizeof(desc), "Ignite 5 enemies carrying your intelligence");
		}
		case 1607: {
			strcopy(ach, sizeof(ach), "Spontaneous Combustion");
			strcopy(desc, sizeof(desc), "Ignite 10 cloaked Spies");
		}
		case 1608: {
			strcopy(ach, sizeof(ach), "Trailblazer");
			strcopy(desc, sizeof(desc), "Ignite 10 enemies that have recently used a teleporter");
		}
		case 1609: {
			strcopy(ach, sizeof(ach), "Camp Fire");
			strcopy(desc, sizeof(desc), "Kill 3 enemies in a row, all within the same area");
		}
		case 1610: {
			strcopy(ach, sizeof(ach), "Lumberjack");
			strcopy(desc, sizeof(desc), "Kill 3 people with your axe in one life");
		}
		case 1611: {
			strcopy(ach, sizeof(ach), "Clearcutter");
			strcopy(desc, sizeof(desc), "Kill 6 people with your axe in one life");
		}
		case 1612: {
			strcopy(ach, sizeof(ach), "Hot on Your Heels");
			strcopy(desc, sizeof(desc), "Kill 50 enemies with your flamethrower, from behind");
		}
		case 1613: {
			strcopy(ach, sizeof(ach), "I Fry");
			strcopy(desc, sizeof(desc), "Ignite 10 disguised Spies");
		}
		case 1614: {
			strcopy(ach, sizeof(ach), "Firewatch");
			strcopy(desc, sizeof(desc), "Ignite 10 Snipers while they are zoomed in");
		}
		case 1615: {
			strcopy(ach, sizeof(ach), "Burn Ward");
			strcopy(desc, sizeof(desc), "Ignite 3 Medics that are ready to deploy an Uber-charge");
		}
		case 1616: {
			strcopy(ach, sizeof(ach), "Hot Potato");
			strcopy(desc, sizeof(desc), "Reflect 100 projectiles with your compressed air blast");
		}
		case 1617: {
			strcopy(ach, sizeof(ach), "Makin' Bacon");
			strcopy(desc, sizeof(desc), "Kill 50 Heavies with your flamethrower");
		}
		case 1618: {
			strcopy(ach, sizeof(ach), "Plan B");
			strcopy(desc, sizeof(desc), "Kill 10 enemies while you're both underwater");
		}
		case 1619: {
			strcopy(ach, sizeof(ach), "Pyrotechnics");
			strcopy(desc, sizeof(desc), "Kill 3 enemies in a single uber-charge");
		}
		case 1620: {
			strcopy(ach, sizeof(ach), "Arsonist");
			strcopy(desc, sizeof(desc), "Destroy 50 Engineer buildings");
		}
		case 1621: {
			strcopy(ach, sizeof(ach), "Controlled Burn");
			strcopy(desc, sizeof(desc), "Ignite 50 enemies capturing one of your control points");
		}
		case 1622: {
			strcopy(ach, sizeof(ach), "Firefighter");
			strcopy(desc, sizeof(desc), "Kill 500 enemies");
		}
		case 1623: {
			strcopy(ach, sizeof(ach), "Pyromancer");
			strcopy(desc, sizeof(desc), "Do 1 million points of total fire damage");
		}
		case 1624: {
			strcopy(ach, sizeof(ach), "Next of Kindling");
			strcopy(desc, sizeof(desc), "Ignite an enemy, and the Medic healing him");
		}
		case 1625: {
			strcopy(ach, sizeof(ach), "OMGWTFBBQ");
			strcopy(desc, sizeof(desc), "Kill an enemy with a taunt");
		}
		case 1626: {
			strcopy(ach, sizeof(ach), "Second Degree Burn");
			strcopy(desc, sizeof(desc), "Kill a burning enemy who was ignited by another Pyro");
		}
		case 1627: {
			strcopy(ach, sizeof(ach), "Got A Light?");
			strcopy(desc, sizeof(desc), "Ignite an enemy Spy while he's flicking a cigarette");
		}
		case 1628: {
			strcopy(ach, sizeof(ach), "BarbeQueQ");
			strcopy(desc, sizeof(desc), "Cause a dominated player to leave the server");
		}
		case 1629: {
			strcopy(ach, sizeof(ach), "Hotshot");
			strcopy(desc, sizeof(desc), "Kill a Soldier with a reflected Critical rocket");
		}
		case 1630: {
			strcopy(ach, sizeof(ach), "Dance Dance Immolation");
			strcopy(desc, sizeof(desc), "Kill 3 enemies while they're taunting");
		}
		case 1631: {
			strcopy(ach, sizeof(ach), "Dead Heat");
			strcopy(desc, sizeof(desc), "Kill an enemy in the same second that he kills you");
		}
		case 1632: {
			strcopy(ach, sizeof(ach), "Pilot Light");
			strcopy(desc, sizeof(desc), "Ignite a rocket-jumping Soldier while he's in midair");
		}
		case 1633: {
			strcopy(ach, sizeof(ach), "Freezer Burn");
			strcopy(desc, sizeof(desc), "Provide enemies with freezecam shots of each of your taunts");
		}
		case 1634: {
			strcopy(ach, sizeof(ach), "Fire Chief");
			strcopy(desc, sizeof(desc), "Kill 1000 enemies");
		}
		case 1635: {
			strcopy(ach, sizeof(ach), "Attention Getter");
			strcopy(desc, sizeof(desc), "Ignite 100 enemies with the flare gun");
		}
		case 1637: {
			strcopy(ach, sizeof(ach), "Pyro Milestone 1");
			strcopy(desc, sizeof(desc), "Obtain 10 of the Pyro achievements");
		}
		case 1638: {
			strcopy(ach, sizeof(ach), "Pyro Milestone 2");
			strcopy(desc, sizeof(desc), "Obtain 16 of the Pyro achievements");
		}
		case 1639: {
			strcopy(ach, sizeof(ach), "Pyro Milestone 3");
			strcopy(desc, sizeof(desc), "Obtain 22 of the Pyro achievements");
		}
		case 1701: {
			strcopy(ach, sizeof(ach), "Triplecrossed");
			strcopy(desc, sizeof(desc), "Backstab 3 Snipers in a single life");
		}
		case 1702: {
			strcopy(ach, sizeof(ach), "For Your Eyes Only");
			strcopy(desc, sizeof(desc), "Provide an enemy with a freezecam shot of you flicking a cigarette onto their corpse");
		}
		case 1703: {
			strcopy(ach, sizeof(ach), "Counter Espionage");
			strcopy(desc, sizeof(desc), "Backstab a disguised Spy");
		}
		case 1704: {
			strcopy(ach, sizeof(ach), "Identity Theft");
			strcopy(desc, sizeof(desc), "Backstab the enemy that you're currently disguised as");
		}
		case 1705: {
			strcopy(ach, sizeof(ach), "The Man From P.U.N.C.T.U.R.E.");
			strcopy(desc, sizeof(desc), "Stab an enemy while fencing");
		}
		case 1706: {
			strcopy(ach, sizeof(ach), "FYI I am a Spy");
			strcopy(desc, sizeof(desc), "Backstab a Medic who has healed you in the last 5 seconds");
		}
		case 1707: {
			strcopy(ach, sizeof(ach), "The Man with the Broken Guns");
			strcopy(desc, sizeof(desc), "Backstab an Engineer, then sap 3 of his buildings within 10 seconds");
		}
		case 1708: {
			strcopy(ach, sizeof(ach), "Sapsucker");
			strcopy(desc, sizeof(desc), "Sap an enemy building, then backstab the Engineer who built it within 5 seconds");
		}
		case 1709: {
			strcopy(ach, sizeof(ach), "May I Cut In?");
			strcopy(desc, sizeof(desc), "Backstab an enemy and the Medic healing him within 10 seconds of each other");
		}
		case 1710: {
			strcopy(ach, sizeof(ach), "Agent Provocateur");
			strcopy(desc, sizeof(desc), "Backstab your Steam Community friends 10 times");
		}
		case 1711: {
			strcopy(ach, sizeof(ach), "The Melbourne Supremacy");
			strcopy(desc, sizeof(desc), "Dominate a Sniper");
		}
		case 1712: {
			strcopy(ach, sizeof(ach), "Spies Like Us");
			strcopy(desc, sizeof(desc), "While cloaked, bump into an enemy cloaked Spy");
		}
		case 1713: {
			strcopy(ach, sizeof(ach), "A Cut Above");
			strcopy(desc, sizeof(desc), "Kill an enemy Spy wielding a Revolver, using your knife");
		}
		case 1714: {
			strcopy(ach, sizeof(ach), "Burn Notice");
			strcopy(desc, sizeof(desc), "Survive 30 seconds after being ignited while cloaked");
		}
		case 1715: {
			strcopy(ach, sizeof(ach), "Die Another Way");
			strcopy(desc, sizeof(desc), "Kill a Sniper after your backstab breaks his Razorback");
		}
		case 1716: {
			strcopy(ach, sizeof(ach), "Constructus Interruptus");
			strcopy(desc, sizeof(desc), "Kill an Engineer who is working on a sentry gun");
		}
		case 1717: {
			strcopy(ach, sizeof(ach), "On Her Majesty's Secret Surface");
			strcopy(desc, sizeof(desc), "Start capping a capture point within a second of it becoming available");
		}
		case 1718: {
			strcopy(ach, sizeof(ach), "Insurance Fraud");
			strcopy(desc, sizeof(desc), "Kill an enemy while you're being healed by an enemy Medic");
		}
		case 1719: {
			strcopy(ach, sizeof(ach), "Point Breaker");
			strcopy(desc, sizeof(desc), "Kill 15 enemies who are standing on a control point they own");
		}
		case 1720: {
			strcopy(ach, sizeof(ach), "High Value Target");
			strcopy(desc, sizeof(desc), "Backstab an enemy who is dominating 3 or more of your teammates");
		}
		case 1721: {
			strcopy(ach, sizeof(ach), "Come In From The Cold");
			strcopy(desc, sizeof(desc), "Get a Revenge kill with a backstab");
		}
		case 1722: {
			strcopy(ach, sizeof(ach), "Wetwork");
			strcopy(desc, sizeof(desc), "Stab an enemy to death while under the influence of Jarate");
		}
		case 1723: {
			strcopy(ach, sizeof(ach), "You Only Shiv Thrice");
			strcopy(desc, sizeof(desc), "Backstab 3 enemies within 10 seconds");
		}
		case 1724: {
			strcopy(ach, sizeof(ach), "Spymaster");
			strcopy(desc, sizeof(desc), "Backstab 1000 enemies");
		}
		case 1725: {
			strcopy(ach, sizeof(ach), "Sap Auteur");
			strcopy(desc, sizeof(desc), "Destroy 1000 Engineer buildings with sappers");
		}
		case 1726: {
			strcopy(ach, sizeof(ach), "Joint Operation");
			strcopy(desc, sizeof(desc), "Sap an enemy sentry gun within 3 seconds of a teammate sapping another");
		}
		case 1727: {
			strcopy(ach, sizeof(ach), "Dr. Nooooo");
			strcopy(desc, sizeof(desc), "Backstab a Medic that is ready to deploy an ÜberCharge");
		}
		case 1728: {
			strcopy(ach, sizeof(ach), "Is It Safe?");
			strcopy(desc, sizeof(desc), "Backstab 50 enemies who are capturing control points");
		}
		case 1729: {
			strcopy(ach, sizeof(ach), "Slash and Burn");
			strcopy(desc, sizeof(desc), "Backstab an enemy, who then switches to Pyro before they respawn");
		}
		case 1730: {
			strcopy(ach, sizeof(ach), "Diplomacy");
			strcopy(desc, sizeof(desc), "Kill 50 enemies with the Ambassador");
		}
		case 1731: {
			strcopy(ach, sizeof(ach), "Skullpluggery");
			strcopy(desc, sizeof(desc), "Headshot 20 Snipers with the Ambassador");
		}
		case 1732: {
			strcopy(ach, sizeof(ach), "Sleeper Agent");
			strcopy(desc, sizeof(desc), "Kill an enemy who triggered your feign death in the last 20 seconds");
		}
		case 1733: {
			strcopy(ach, sizeof(ach), "Who's Your Daddy?");
			strcopy(desc, sizeof(desc), "Headshot 3 Scouts with the Ambassador");
		}
		case 1734: {
			strcopy(ach, sizeof(ach), "Deep Undercover");
			strcopy(desc, sizeof(desc), "While using the Cloak and Dagger, kill the same enemy 3 times, all within the same area in a single life");
		}
		case 1735: {
			strcopy(ach, sizeof(ach), "Spy Milestone 1");
			strcopy(desc, sizeof(desc), "Obtain 5 of the Spy achievements");
		}
		case 1736: {
			strcopy(ach, sizeof(ach), "Spy Milestone 2");
			strcopy(desc, sizeof(desc), "Obtain 11 of the Spy achievements");
		}
		case 1737: {
			strcopy(ach, sizeof(ach), "Spy Milestone 3");
			strcopy(desc, sizeof(desc), "Obtain 17 of the Spy achievements");
		}
        case 1801: {
            strcopy(ach, sizeof(ach), "Engineer Milestone 1");
            strcopy(desc, sizeof(desc), "Achieve 5 of the achievements in the Engineer pack");
        }
        case 1802: {
            strcopy(ach, sizeof(ach), "Engineer Milestone 2");
            strcopy(desc, sizeof(desc), "Achieve 11 of the achievements in the Engineer pack");	
		}
        case 1803: {
            strcopy(ach, sizeof(ach), "Engineer Milestone 3");
            strcopy(desc, sizeof(desc), "Achieve 17 of the achievements in the Engineer pack");
		 }
        case 1804: {
            strcopy(ach, sizeof(ach), "Revengineering");
            strcopy(desc, sizeof(desc), "Use a revenge crit to kill the player that destroyed your sentry gun");	
        }
        case 1805: {
            strcopy(ach, sizeof(ach), "Battle Rustler");
            strcopy(desc, sizeof(desc), "Teleport 100 team members into battle");
        }
        case 1806: {
            strcopy(ach, sizeof(ach), "The Extinguished Gentleman");
            strcopy(desc, sizeof(desc), "Have dispensers you built extinguish 20 burning players");	
        }
        case 1807: {
            strcopy(ach, sizeof(ach), "Search Engine");
            strcopy(desc, sizeof(desc), "Kill 3 cloaked spies with a sentry gun under control of your Wrangler");
        }
        case 1808: {
            strcopy(ach, sizeof(ach), "Unforgiven");
            strcopy(desc, sizeof(desc), "Kill 3 enemies with revenge crits without dying");
		}
        case 1809: {
            strcopy(ach, sizeof(ach), "Building Block");
            strcopy(desc, sizeof(desc), "Have a sentry shielded by the Wrangler absorb 500 damage without being destroyed");
        }
        case 1810: {
            strcopy(ach, sizeof(ach), "Powned on the Range");
            strcopy(desc, sizeof(desc), "Kill 10 enemies outside the normal sentry gun range using the Wrangler");
        }
        case 1811: {
            strcopy(ach, sizeof(ach), "Silent Pardner");
            strcopy(desc, sizeof(desc), "Upgrade 50 buildings built by other team members");
		}
        case 1812: {
            strcopy(ach, sizeof(ach), "Doc Holiday");
            strcopy(desc, sizeof(desc), "Have a dispenser heal 3 teammates at the same time");	
		}
        case 1813: {
            strcopy(ach, sizeof(ach), "Best Little Slaughterhouse In Texas");
            strcopy(desc, sizeof(desc), "Rack up 5000 kills with your sentry guns");
       	}
        case 1814: {
            strcopy(ach, sizeof(ach), "Death Metal");
            strcopy(desc, sizeof(desc), "Pick up 10,000 waste metal from pieces of destroyed buildings"); 
	    }
        case 1815: {
            strcopy(ach, sizeof(ach), "Trade Secrets");
            strcopy(desc, sizeof(desc), "Kill 20 players carrying the intelligence"); 	
		}
        case 1816: {
            strcopy(ach, sizeof(ach), "The Wrench Connection");
            strcopy(desc, sizeof(desc), "Kill a disguised spy with your Wrench"); 	
        }
        case 1817: {
            strcopy(ach, sizeof(ach), "Land Grab");
            strcopy(desc, sizeof(desc), "Help a teammate construct a building");	
        }
        case 1818: {
            strcopy(ach, sizeof(ach), "Six-string Stinger");
            strcopy(desc, sizeof(desc), "Provide an enemy player with a freeze cam of your guitar playing skills");	
        }
        case 1819: {
            strcopy(ach, sizeof(ach), "Uncivil Engineer");
            strcopy(desc, sizeof(desc), "Provide an enemy player with a freeze cam of you and the sentry that just killed them");
		}
        case 1820: {
            strcopy(ach, sizeof(ach), "Texas Two-Step");
            strcopy(desc, sizeof(desc), "Use a sentry gun to kill 25 enemy players that are capturing a point");
        }
        case 1821: {
            strcopy(ach, sizeof(ach), "Frontier Justice");
            strcopy(desc, sizeof(desc), "Have your sentry kill the enemy that just killed you within 10 seconds");	
        }
        case 1822: {
            strcopy(ach, sizeof(ach), "Doc, Stock and Barrel");
            strcopy(desc, sizeof(desc), "Repair a sentry gun under fire while being healed by a Medic");
		}
        case 1823: {
            strcopy(ach, sizeof(ach), "No Man's Land");
            strcopy(desc, sizeof(desc), "Use a sentry gun to kill 25 enemy players that are capturing a point");
        }
        case 1824: {
            strcopy(ach, sizeof(ach), "Fistful of Sappers");
            strcopy(desc, sizeof(desc), "Destroy 25 sappers on buildings built by other team members");	
        }
        case 1825: {
            strcopy(ach, sizeof(ach), "Quick Draw");
            strcopy(desc, sizeof(desc), "Kill a spy and two sappers within 10 seconds");
        }
        case 1826: {
            strcopy(ach, sizeof(ach), "Get Along");
            strcopy(desc, sizeof(desc), "Manage to get to and then remove a sapper placed on your building while you were several meters away");
        }
        case 1827: {
            strcopy(ach, sizeof(ach), "Honky Tonky Man");
            strcopy(desc, sizeof(desc), "Smash an enemy player's head in with your guitar");	
        }
        case 1828: {
            strcopy(ach, sizeof(ach), "How the Pests Was Gunned");
            strcopy(desc, sizeof(desc), "Destroy 50 enemy stickybombs lying in range of friendly buildings");
        }
        case 1830: {
            strcopy(ach, sizeof(ach), "Breaking Morant");
            strcopy(desc, sizeof(desc), "Kill 10 Snipers with a sentry gun under control of your Wrangler");	
        }
        case 1831: {
            strcopy(ach, sizeof(ach), "Patent Protection");
            strcopy(desc, sizeof(desc), "Destroy an enemy Engineer's sentry gun with a sentry under control of your Wrangler");	
        }
        case 1832: {
            strcopy(ach, sizeof(ach), "If You Build It, They Will Die");
            strcopy(desc, sizeof(desc), "Haul a level 3 sentry gun into a position where it achieves a kill shortly after being redeployed");
        }
        case 1833: {
            strcopy(ach, sizeof(ach), "Texas Ranger");
            strcopy(desc, sizeof(desc), "Haul buildings 1 km over your career");	
        }
        case 1834: {
            strcopy(ach, sizeof(ach), "Deputized");
            strcopy(desc, sizeof(desc), "Get 10 assists with another Engineer where a sentry gun was involved in the kill");
        }
        case 1835: {
            strcopy(ach, sizeof(ach), "Drugstore Cowboy");
            strcopy(desc, sizeof(desc), "Have dispensers you created dispense a combined amount of 100,000 health over your career");	
        }
        case 1836: {
            strcopy(ach, sizeof(ach), "Circl Of Wagons");
            strcopy(desc, sizeof(desc), "Repair 50,000 damage to friendly buildings constructed by other players");	
        }
        case 1837: {
            strcopy(ach, sizeof(ach), "Build to Last");
            strcopy(desc, sizeof(desc), "Help a single building tank over 2000 damage without being destroyed");
        }
        case 1838: {
            strcopy(ach, sizeof(ach), "(Not so) Loney Are the Brave");
            strcopy(desc, sizeof(desc), "Keep a Heavy healed with your dispenser while he gains 5 kills");			
		}
		case 1901: {
			strcopy(ach, sizeof(ach), "Candy Coroner");
			strcopy(desc, sizeof(desc), "Collect 20 Halloween pumpkins from dead players to unlock a hat");
		}
		case 1902: {
			strcopy(ach, sizeof(ach), "Ghastly Gibus Grab");
			strcopy(desc, sizeof(desc), "Dominate a player wearing the Ghastly gibus to earn your own");
		}
		case 1903: {
			strcopy(ach, sizeof(ach), "Scared Stiff");
			strcopy(desc, sizeof(desc), "Kill a player scared by the ghost haunting KOTH Harvest");
		}
		case 1904: {
			strcopy(ach, sizeof(ach), "Attack o' Lantern");
			strcopy(desc, sizeof(desc), "Cause the deaths of 5 players by exploding nearby pumpkin bombs");
		}
		case 1905: {
			strcopy(ach, sizeof(ach), "Costume Contest");
			strcopy(desc, sizeof(desc), "Kill a Spy disguised as your current class");
		}
		case 1906: {
			strcopy(ach, sizeof(ach), "Sleepy HollOWND");
			strcopy(desc, sizeof(desc), "Kill the Horseless Headless Horsemann");
		}
		case 1907: {
			strcopy(ach, sizeof(ach), "Masked Mann");
			strcopy(desc, sizeof(desc), "Collect the Haunted Halloween Gift in Mann Manor");
        }
		case 1908: {
			strcopy(ach, sizeof(ach), "Sackston Hale");
			strcopy(desc, sizeof(desc), "Craft the Saxton Hale Mask");
         }
		case 1909: {
			strcopy(ach, sizeof(ach), "Gored!");
			strcopy(desc, sizeof(desc), "Collect the Horseless Headless Horsemann's Haunted Metal");			
		}
		default: {
			PrintToChatAll("Unknown Achievement");
			LogError("Unrecognised Achievement. ID: %d", id);
			return Plugin_Continue;
		}
	}
	
	if(display == 2) {
		PrintHintTextToAll("\x04%s\x01: %s", ach, desc);
	} else {
		PrintToChatAll("\x04%s\x01: %s", ach, desc);
	}
	
	return Plugin_Continue;
}
