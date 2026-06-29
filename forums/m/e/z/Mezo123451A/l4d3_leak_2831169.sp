#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.4.3"
#define MIN_DELAY 30.0
#define MAX_DELAY 200.0
#define MAX_MESSAGE_LENGTH 512
#define MAX_FEATURES 100

// Global variables for vote tracking
bool g_HasVoted[MAXPLAYERS + 1];
bool g_bFirstJoin[MAXPLAYERS + 1];
char g_PlayerVotes[MAXPLAYERS + 1][64];

ConVar g_hMinDelay;
ConVar g_hMaxDelay;
ConVar g_hEnabled;
ConVar g_hHackingEnabled;
ConVar g_hLeakMessagesEnabled;
Handle g_hTimer = null;
Handle g_hHelpTimer = null;
ArrayList g_Messages = null;
ArrayList g_ClassifiedInfo = null;
KeyValues g_kvVotes;

bool g_bPlayerHacking[MAXPLAYERS+1];
int g_iHackProgress[MAXPLAYERS+1];
float g_fNextHackTime[MAXPLAYERS+1];
int g_iHackSuccesses[MAXPLAYERS+1];
int g_iHackFails[MAXPLAYERS+1]; 
float g_fNextHackAttempt[MAXPLAYERS+1];
int g_iHackDifficulty[MAXPLAYERS+1];

bool g_SurveyActive = true;  // Keep survey running
Handle g_UpdateTimer = null;  // Timer for updates

public Plugin myinfo = {
    name = "L4D3 Leaks",
    author = "Mezo123451A", 
    description = "The origin of this plugin is unknown. Use at your own risk...",
    version = PLUGIN_VERSION,
    url = ""
};

void AddMessage(const char[] message) {
    g_Messages.PushString(message);
}

public void OnPluginStart() {
    // Register admin commands
    RegConsoleCmd("sm_l4d3test", Command_TestL4D3Menu, "Opens the L4D3 survey menu");
    RegConsoleCmd("sm_resetvote", Command_ResetVote, "Resets your vote status");
    RegAdminCmd("sm_togglesurvey", Command_ToggleSurvey, ADMFLAG_ROOT, "Toggles the L4D3 survey on/off");

    // Create ConVars
    CreateConVar("l4d3_leak_version", PLUGIN_VERSION, "L4D3 Leak Plugin Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
    g_hMinDelay = CreateConVar("l4d3_leak_min_delay", "30.0", "Minimum delay between messages (in seconds)", FCVAR_NOTIFY, true, 1.0);
    g_hMaxDelay = CreateConVar("l4d3_leak_max_delay", "200.0", "Maximum delay between messages (in seconds)", FCVAR_NOTIFY, true, 1.0);
    g_hLeakMessagesEnabled = CreateConVar("l4d3_leak_messages_enabled", "0", "Enable/disable the L4D3 leak messages (DISABLED)", FCVAR_NOTIFY, true, 0.0, true, 0.0);
    g_hHackingEnabled = CreateConVar("l4d3_leak_hacking", "1", "Enable/disable the hacking system (1 = enabled, 0 = disabled)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    
    // Hook ConVar changes
    g_hLeakMessagesEnabled.AddChangeHook(ConVarChanged_LeakMessages);
    g_hHackingEnabled.AddChangeHook(ConVarChanged_HackingEnabled);
    
    // Register commands
    RegConsoleCmd("sm_hack", Command_HackSystem, "Attempt to hack the system");
    RegConsoleCmd("sm_decrypt", Command_Decrypt, "Continue the hacking process");
    
    // Initialize arrays
    delete g_Messages;
    delete g_ClassifiedInfo;
    g_Messages = new ArrayList(MAX_MESSAGE_LENGTH);
    g_ClassifiedInfo = new ArrayList(MAX_MESSAGE_LENGTH);
    
    // Initialize player arrays
    for (int i = 1; i <= MaxClients; i++) {
        g_bPlayerHacking[i] = false;
        g_iHackProgress[i] = 0;
        g_fNextHackTime[i] = 0.0;
        g_iHackSuccesses[i] = 0;
        g_iHackFails[i] = 0;
        g_fNextHackAttempt[i] = 0.0;
        g_iHackDifficulty[i] = 1;
        g_bFirstJoin[i] = true;
        g_HasVoted[i] = false;
        g_PlayerVotes[i][0] = '\0';
    }
    
    // Initialize vote storage
    g_kvVotes = new KeyValues("L4D3Votes");
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "data/l4d3_votes.txt");
    
    // Create directory if it doesn't exist
    char dir[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, dir, sizeof(dir), "data");
    if (!DirExists(dir)) {
        CreateDirectory(dir, 511);
    }
    
    if (!g_kvVotes.ImportFromFile(path)) {
        g_kvVotes.ExportToFile(path);
    }
    
    // Load messages and classified info
    LoadMessages();
    LoadClassifiedInfo();
    
    // Create config file
    AutoExecConfig(true);
    
    // Force reload timer
    delete g_hTimer;
    g_hTimer = null;
    
    // Create message timer if enabled
    if (g_hLeakMessagesEnabled.BoolValue) {
        CreateMessageTimer();
    }
    
    // Create help message timer
    CreateHelpTimer();
    
    // Start periodic updates
    if (g_UpdateTimer != null) {
        KillTimer(g_UpdateTimer);
        g_UpdateTimer = null;
    }
    g_UpdateTimer = CreateTimer(80.0, Timer_UpdateResults, _, TIMER_REPEAT);
    
    // Debug message to server console
    PrintToServer("[L4D3 Leaks] OnPluginStart - Messages: %d, Classified: %d, Timer: %d, Messages Enabled: %d, Hacking Enabled: %d", 
        g_Messages.Length, 
        g_ClassifiedInfo.Length,
        g_hTimer != null, 
        g_hLeakMessagesEnabled.BoolValue,
        g_hHackingEnabled.BoolValue);
}

public void OnMapStart() {
    // New mysterious version
    CreateConVar("l4d3_beta_build", "██.███.███", "ERROR: DATA CORRUPTED", FCVAR_NOTIFY|FCVAR_DONTRECORD);
    CreateConVar("l4d3_beta_access", "ERROR", "ACCESS DENIED - SECURITY LEVEL ██", FCVAR_NOTIFY|FCVAR_DONTRECORD); 
    CreateConVar("l4d3_beta_status", "[REDACTED]", "CONTACT ADMINISTRATOR ███-███-████", FCVAR_NOTIFY|FCVAR_DONTRECORD);
    
    // Create directory structure
    char dirPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, dirPath, sizeof(dirPath), "data/l4d3_votes");
    if (!DirExists(dirPath)) {
        CreateDirectory(dirPath, 511);
    }
    
    // Initialize messages if needed
    if (g_Messages == null) {
        g_Messages = new ArrayList(MAX_MESSAGE_LENGTH);
        LoadMessages();
    }
    
    // Safely handle timer
    if (g_hTimer != null) {
        delete g_hTimer;
        g_hTimer = null;
    }
    
    // Create new timer if enabled and ConVar is valid
    if (g_hLeakMessagesEnabled != null && g_hLeakMessagesEnabled.BoolValue) {
        CreateMessageTimer();
    }
    
    // Debug message to server console
    PrintToServer("[L4D3 Leaks] OnMapStart - Messages: %d, Timer: %d, Messages Enabled: %d", 
        g_Messages.Length, 
        g_hTimer != null, 
        (g_hLeakMessagesEnabled != null) ? g_hLeakMessagesEnabled.BoolValue : false);
}

public void OnPluginEnd() {
    // Safely delete timers if they exist
    if (g_hTimer != null) {
        delete g_hTimer;
        g_hTimer = null;
    }
    
    if (g_UpdateTimer != null) {
        KillTimer(g_UpdateTimer);
        g_UpdateTimer = null;
    }
    
    if (g_hHelpTimer != null) {
        delete g_hHelpTimer;
        g_hHelpTimer = null;
    }
    
    // Clear ConVar handles
    g_hLeakMessagesEnabled = null;
    g_hHackingEnabled = null;
    g_hMinDelay = null;
    g_hMaxDelay = null;
    delete g_kvVotes;
}

public void ConVarChanged_Enabled(ConVar convar, const char[] oldValue, const char[] newValue) {
    bool enabled = g_hEnabled.BoolValue;
    
    if (enabled && g_hTimer == null) {
        CreateMessageTimer();
    }
    else if (!enabled && g_hTimer != null) {
        delete g_hTimer;
        g_hTimer = null;
    }
}

void CreateMessageTimer() {
    delete g_hTimer;
    g_hTimer = CreateTimer(1.0, Timer_CheckMessages, _, TIMER_REPEAT);
    PrintToServer("[L4D3 Leaks] Created message timer");
}

public Action Timer_SendMessage(Handle timer) {
    g_hTimer = null;
    
    if (!g_hEnabled.BoolValue) {
        PrintToServer("[L4D3 Leaks] Timer stopped - plugin disabled");
        return Plugin_Stop;
    }
    
    int messageCount = g_Messages.Length;
    int randomIndex = GetRandomInt(0, messageCount - 1);
    
    char message[MAX_MESSAGE_LENGTH];
    g_Messages.GetString(randomIndex, message, sizeof(message));
    
    SendLeakMessage(message);
    PrintToServer("[L4D3 Leaks] Sent message: %s", message);
    
    CreateMessageTimer();
    
    return Plugin_Continue;
}

void LoadMessages() {
    // Delete existing array if it exists
    delete g_Messages;
    
    g_Messages = new ArrayList(MAX_MESSAGE_LENGTH);
    
    // Special Infected Evolution
    AddMessage("CEDA Alert: Hunter specimens developing pack-hunting behaviors in groups of ██████");
    AddMessage("Mutation Report: Boomer bile now attracts special infected within ██████ meter radius");
    AddMessage("Field Study: Tank aggression increases by ██████% when exposed to pipe bomb stimuli");
    AddMessage("Warning: Witch reaction time decreased to ██████ seconds after startling");
    AddMessage("Infected Update: Spitter acid pools now affect vertical surfaces for ██████ duration");

    // Survivor Equipment
    AddMessage("Field Test: Upgraded health kits now counter ██████ damage from special infected");
    AddMessage("Gear Report: New flashlight attachment reveals Smoker ██████ through walls");
    AddMessage("Supply Drop: Experimental molotovs create flame barrier lasting ██████ seconds");
    AddMessage("Equipment Log: Survivor backpacks can now store ██████ additional items");
    AddMessage("Medical Update: Adrenaline shots temporarily highlight nearby ██████ in red");

    // Weapon Modifications
    AddMessage("Arsenal Note: Desert Eagle effective against ██████ at ranges exceeding 40 meters");
    AddMessage("R&D Success: Modified AK-47 penetrates multiple infected with ██████ rounds");
    AddMessage("Weapon Test: Combat shotgun fitted with ██████ for increased stopping power");
    AddMessage("Equipment: Chainsaw fuel mixture now includes ██████ for extended operation");
    AddMessage("Ammo Type: New explosive rounds detonate on impact with ██████ infected");

    // Environmental Hazards
    AddMessage("Weather Alert: Rain reduces visibility of ██████ special infected types");
    AddMessage("Terrain Report: Mud slows infected movement by ██████%, affects survivor stamina");
    AddMessage("Urban Warning: Car alarms now attract ██████ within expanded radius");
    AddMessage("Safety Alert: Electric fences effective against ██████ for limited time");
    AddMessage("Hazard Update: Gas station explosions now affect area of ██████ meters");

        // Combat Mechanics
    AddMessage("Tactics Update: Survivors can now use infected bodies as temporary ██████ cover");
    AddMessage("Combat Log: Melee weapons break special infected grip after ██████ consecutive hits");
    AddMessage("Battle Report: Shoving effectiveness increased against ██████ when timed properly");
    AddMessage("Field Manual: Coordinated fire increases damage to Tank by ██████ percent");
    AddMessage("Combat Tip: Crouching reduces sound radius by ██████ while moving");

    // Infected Behavior
    AddMessage("Horde Analysis: Common infected now attempt to ██████ survivors from high ground");
    AddMessage("Behavior Study: Jockey specimens coordinate attacks with ██████ special infected");
    AddMessage("Alert: Charger now targets survivors carrying ██████ as priority");
    AddMessage("Update: Smoker tongue can now pull victims around ██████ corners");
    AddMessage("Warning: Tank AI learns from ██████ failed attack patterns");

    // Safe Room Features
    AddMessage("Security Log: New safe room defenses include ██████ automated system");
    AddMessage("Supply Cache: Emergency button releases ██████ during overwhelming attacks");
    AddMessage("Room Update: Medical stations can now ██████ between survivor visits");
    AddMessage("Defense Report: Reinforced doors withstand Tank damage for ██████ seconds");
    AddMessage("Equipment Note: Safe room weapon upgrades now include ██████ modifications"),

    // Map Mechanics
    AddMessage("Navigation: Alternative routes unlock after ██████ special infected defeats");
    AddMessage("Area Update: Storm drains provide escape from ██████ if properly timed");
    AddMessage("Terrain Alert: Collapsing buildings create ██████ temporary safe zones");
    AddMessage("Urban Design: Subway tunnels flood when ██████ power stations activate");
    AddMessage("Map Feature: Radio towers can be activated to ██████ nearby hordes");

        // Team Dynamics
    AddMessage("Squad Update: Survivors within 3 meters share ██████ resistance bonus");
    AddMessage("Team Tactics: Coordinated melee attacks stagger Tank for ██████ seconds");
    AddMessage("Group Bonus: Multiple survivors using same weapon type increase ██████ effect");
    AddMessage("Cooperation: Helping incapped teammates reduces recovery time by ██████");
    AddMessage("Team Alert: Survivors can now mark special infected for ██████ seconds");

    // Witch Mechanics
    AddMessage("Witch Study: Crying becomes erratic when ██████ survivors are nearby");
    AddMessage("Behavior Log: Witch follows distant gunfire after ██████ minutes of exposure");
    AddMessage("Warning: Startled Witch can now ██████ between multiple targets");
    AddMessage("Update: Witch reaction to flashlights varies based on ██████ level");
    AddMessage("Alert: Multiple Witches show pack behavior in ██████ environments");

    // Horde Mechanics
    AddMessage("Crowd Control: Hordes now attempt to ██████ survivors into special infected");
    AddMessage("Swarm Update: Infected climb faster when ██████ survivors are above");
    AddMessage("Horde Alert: Common infected protect ██████ special infected during attacks");
    AddMessage("Behavior Change: Hordes target survivors carrying ██████ as priority");
    AddMessage("Movement Update: Infected hordes now use ██████ to reach survivors faster");

    // Emergency Events
    AddMessage("Event Warning: Helicopter crash attracts ██████ special infected types");
    AddMessage("Emergency: Bridge collapse creates alternate path through ██████");
    AddMessage("Alert System: Car alarms chain react within ██████ meter radius");
    AddMessage("Crisis Update: Emergency doors malfunction after ██████ Tank hits");
    AddMessage("Event Trigger: Power station activation causes ██████ in nearby areas");

        // Tank Variations
    AddMessage("Tank Alert: Armored variant requires ██████ shots to vulnerable points");
    AddMessage("Mutation: Fire-resistant Tank specimen observed in ██████ industrial zone");
    AddMessage("Warning: Tank now uses defeated survivors as ██████ projectile weapons");
    AddMessage("Behavior Change: Tank specimens coordinate attacks with ██████ special infected");
    AddMessage("Update: Enraged Tank can destroy safe room doors in ██████ seconds");

    // Weapon Upgrades
    AddMessage("Upgrade Station: Shotguns can be modified for ██████ spread pattern");
    AddMessage("Ammo Types: Electric shells temporarily stun ██████ special infected");
    AddMessage("Modification: Silenced weapons reduce chance of alerting ██████");
    AddMessage("Arsenal Update: Dual pistols now support ██████ alternate fire mode");
    AddMessage("Equipment: Baseball bat wrapped in ██████ causes electrical damage");

    // Survivor Status Effects
    AddMessage("Medical Note: Adrenaline shots temporarily reveal ██████ through walls");
    AddMessage("Health System: Pain pills effectiveness scales with ██████ status");
    AddMessage("Status Effect: Bile bombs provide brief immunity to ██████ damage");
    AddMessage("Condition Update: Limping survivors attract nearby ██████ attention");
    AddMessage("Medical Alert: Defibrillator charge affected by ██████ weather conditions");

    // Environmental Interaction
    AddMessage("Terrain Update: Survivors can now use dumpsters to ██████ special infected");
    AddMessage("Physics Change: Propane tanks explode in chain reaction within ██████ meters");
    AddMessage("Environment: Rain reduces effectiveness of ██████ molotov cocktails");
    AddMessage("Interaction: Survivors can push cars to create ██████ defensive positions");
    AddMessage("Feature Update: Elevators can be used to ██████ pursuing infected");

        // Special Infected Cooperation
    AddMessage("Threat Alert: Smoker can now coordinate tongue pulls with ██████ Charger attacks");
    AddMessage("Behavior Study: Jockey steers victims towards ██████ Spitter acid pools");
    AddMessage("Hunter Pack: Multiple Hunters now perform ██████ synchronized pounces");
    AddMessage("Tactical Update: Boomer bile attracts nearby ██████ special infected");
    AddMessage("Warning: Special infected now prioritize survivors using ██████ equipment");

    // Advanced Survivor Tactics
    AddMessage("Combat Tip: Survivors can now shoot while ██████ from ledges");
    AddMessage("Movement Update: Quick-turn feature added when ██████ special infected nearby");
    AddMessage("Defense Tactic: Melee weapons deflect Smoker tongues if ██████ correctly");
    AddMessage("Team Move: Survivors can help others climb ██████ faster");
    AddMessage("New Ability: Emergency dodge roll available after ██████ consecutive hits");

    // Urban Navigation
    AddMessage("City Alert: Subway tunnels flood after ██████ minutes of generator use");
    AddMessage("Route Update: Fire escapes collapse after ██████ survivors cross");
    AddMessage("Path Finding: Infected hordes use sewers to ██████ survivor positions");
    AddMessage("Building Status: Office towers can be traversed via ██████ maintenance paths");
    AddMessage("Navigation: Destroyed walls create ██████ shortcuts through buildings");

    // Weather Effects
    AddMessage("Storm Warning: Lightning strikes attract ██████ special infected");
    AddMessage("Fog System: Dense fog conceals ██████ until close range");
    AddMessage("Rain Effect: Wet surfaces cause infected to ██████ while charging");
    AddMessage("Weather Alert: Strong winds affect molotov ██████ trajectory");
    AddMessage("Environment: Thunder sounds mask ██████ special infected audio cues");

        // Panic Events
    AddMessage("Warning: New alarm system triggers waves of ██████ climbing infected");
    AddMessage("Event Update: Stadium lights attract massive horde from ██████ direction");
    AddMessage("Alert System: Train horn summons Tank after ██████ seconds");
    AddMessage("Panic Trigger: Breaking mall glass now attracts ██████ special infected");
    AddMessage("Event Chain: Multiple car alarms create ██████ super-horde event");

    // Weapon Combinations
    AddMessage("Arsenal Note: Molotov combined with pipe bomb creates ██████ trap");
    AddMessage("Loadout Tip: Dual wielding pistols with ██████ increases fire rate");
    AddMessage("Equipment: Bile jar can be combined with ██████ for chain reaction");
    AddMessage("Weapon Mod: Shotgun shells can be packed with ██████ for area denial");
    AddMessage("Combat Update: Melee weapons dipped in Spitter acid cause ██████ damage");

    // Survivor Communication
    AddMessage("Team System: Marking special infected reveals them for ██████ seconds");
    AddMessage("Voice Update: Survivors automatically call out ██████ item locations");
    AddMessage("Alert Feature: Characters warn teammates of ██████ approaching from behind");
    AddMessage("Team Chat: Quick commands added for ██████ tactical situations");
    AddMessage("Ping System: Survivors can now mark ██████ escape routes"),

    // Infected Ambush
    AddMessage("Threat Warning: Special infected can now ██████ from ceiling vents");
    AddMessage("Ambush Alert: Infected emerge from ██████ when survivors pass");
    AddMessage("Tactical Update: Common infected play dead until ██████ approach");
    AddMessage("Hunter Behavior: Pack attacks coordinated through ██████ howls");
    AddMessage("Spawn System: Special infected utilize ██████ for surprise attacks");

        // Safe House Mechanics
    AddMessage("Security Update: Safe rooms now include ██████ emergency defense system");
    AddMessage("Supply Drop: Each safe room contains one random ██████ special item");
    AddMessage("Room Feature: Medical cabinet restocks after ██████ minutes");
    AddMessage("Defense System: Safe room doors hold for ██████ seconds against Tank");
    AddMessage("Equipment: Emergency button releases ██████ to cover escape");

    // Boomer Variants
    AddMessage("Mutation Alert: New Boomer bile causes infected to ██████ survivors");
    AddMessage("Hazard Warning: Boomer explosion now includes ██████ damage radius");
    AddMessage("Bile Effect: Upgraded bile attracts special infected for ██████ seconds");
    AddMessage("New Strain: Female Boomer bile has ██████ increased range");
    AddMessage("Threat Level: Bile now dissolves survivor armor over ██████ seconds");

    // Rescue Vehicles
    AddMessage("Transport Update: Helicopter pilot will wait maximum of ██████ minutes");
    AddMessage("Vehicle Status: Rescue boat requires ██████ to start engine");
    AddMessage("Escape Route: Train departure triggers special ██████ event");
    AddMessage("Transport Alert: Military APC provides mobile ██████ during escape");
    AddMessage("Vehicle Defense: Rescue chopper equipped with ██████ defense system");

    // Crescendo Events
    AddMessage("Event Warning: Rock concert equipment attracts ██████ mega horde");
    AddMessage("Noise Alert: Church bells summon new infected type from ██████");
    AddMessage("Stadium Update: Sports arena lights trigger ██████ special infected");
    AddMessage("Event Chain: Carnival rides activate in sequence causing ██████");
    AddMessage("Warning: Airport announcement system draws hordes from ██████ terminals");

        // Charger Mechanics
    AddMessage("Impact Alert: Charger can now smash through ██████ weak walls");
    AddMessage("Behavior Update: Multiple Chargers coordinate ██████ ram attacks");
    AddMessage("Charge Path: Survivor impact creates ██████ damage to nearby infected");
    AddMessage("New Ability: Charger recovers faster after ██████ successful hits");
    AddMessage("Tactical Change: Charger now targets survivors carrying ██████");

    // Survivor Perks
    AddMessage("Skill Tree: Extended melee training unlocks ██████ combo attacks");
    AddMessage("Perk Update: Headshot streak increases accuracy by ██████ percent");
    AddMessage("Ability Unlock: Perfect reloads grant temporary ██████ bonus");
    AddMessage("Team Perk: Staying close to teammates reduces ██████ damage");
    AddMessage("Combat Bonus: Successfully shoving special infected grants ██████");

    // Mall Environment
    AddMessage("Store Alert: Clothing racks can be toppled to slow ██████ advance");
    AddMessage("Mall Update: Escalators change direction every ██████ seconds");
    AddMessage("Security Gate: Metal shutters hold against hordes for ██████");
    AddMessage("Food Court: Kitchen equipment can be used to create ██████");
    AddMessage("Shop Defense: Glass storefronts shatter after ██████ impacts");

    // Hospital Setting
    AddMessage("Medical Wing: Operating rooms contain rare ██████ supplies");
    AddMessage("Emergency Alert: Power failure releases infected from ██████");
    AddMessage("Hospital Update: Elevator requires ██████ to power emergency mode");
    AddMessage("Quarantine Zone: Isolation ward houses new ██████ infected type");
    AddMessage("Medical Supply: Experimental treatment stored in ██████ freezer");

        // Smoker Tactics
    AddMessage("Ability Update: Smoker tongue now pulls victims through ██████");
    AddMessage("Smoke Screen: Dense smoke cloud disorients survivors for ██████ seconds");
    AddMessage("Tactical Note: Multiple Smokers can now ██████ single target");
    AddMessage("Evolution: Smoker regenerates tongue faster in ██████ environments");
    AddMessage("New Ability: Smoke residue reveals survivor positions for ██████");

    // Military Presence
    AddMessage("Army Protocol: Automated turrets distinguish between ██████ types");
    AddMessage("Defense Line: Military checkpoint contains experimental ██████");
    AddMessage("Radio Update: Emergency broadcast reveals location of ██████");
    AddMessage("Evacuation: Military convoy departs in ██████ after signal");
    AddMessage("Combat Zone: Air support available after activating ██████");

    // Subway System
    AddMessage("Transit Alert: Moving trains attract hordes from ██████ tunnels");
    AddMessage("Power Status: Live rails effective against ██████ infected types");
    AddMessage("Station Update: PA system can be used to ██████ infected movement");
    AddMessage("Tunnel Warning: Maintenance areas contain sleeping ██████");
    AddMessage("Track Status: Subway cars provide mobile ██████ between stations");

    // Weather Impact
    AddMessage("Storm Warning: Lightning strikes ignite ██████ creating fire hazards");
    AddMessage("Rain Effect: Wet conditions reduce effectiveness of ██████");
    AddMessage("Fog Bank: Dense fog conceals approach of ██████ special infected");
    AddMessage("Weather Alert: Strong winds affect trajectory of ██████");
    AddMessage("Temperature: Freezing conditions slow infected by ██████ percent");

        // Spitter Evolution
    AddMessage("Acid Warning: Spitter projectiles now bounce off ██████ surfaces");
    AddMessage("Mutation Note: Acid pools remain active for ██████ additional seconds");
    AddMessage("Hazard Alert: Spitter acid now corrodes ██████ creating new paths");
    AddMessage("Behavior Change: Spitters target groups of ██████ or more survivors");
    AddMessage("Acid Effect: Multiple acid pools combine to create ██████ reaction");

    // Construction Site
    AddMessage("Site Warning: Crane can be operated to move ██████ between floors");
    AddMessage("Safety Alert: Cement mixer attracts horde when ██████ activated");
    AddMessage("Structure Note: Scaffolding collapses after ██████ infected cross");
    AddMessage("Tool Update: Nail gun effective against ██████ at close range");
    AddMessage("Site Hazard: Paint cans explode when ██████ creating distraction");

    // Survivor Equipment
    AddMessage("Gear Update: Riot shield blocks damage from ██████ special infected");
    AddMessage("Item Find: Flare gun marks location of ██████ for team");
    AddMessage("New Tool: Grappling hook allows quick escape from ██████");
    AddMessage("Equipment: Portable UV light reveals ██████ infected traces");
    AddMessage("Backpack: Expanded inventory holds additional ██████ items");

    // Witch Behavior
    AddMessage("Behavior Log: Witch follows survivors who ██████ at a distance");
    AddMessage("Crying Update: Witch becomes more aggressive near ██████");
    AddMessage("Movement Note: Witch can now pursue targets through ██████");
    AddMessage("Alert Status: Multiple Witches respond to ██████ in vicinity");
    AddMessage("New Pattern: Witch temporarily blinded by ██████ light source");

        // Jockey Tactics
    AddMessage("Behavior Update: Jockey can leap between victims after ██████ seconds");
    AddMessage("Control Pattern: Extended ride time when steering towards ██████");
    AddMessage("Pack Tactics: Multiple Jockeys coordinate to lead survivors into ██████");
    AddMessage("New Ability: Jockey can temporarily control ██████ special infected");
    AddMessage("Movement Update: Increased steering control near ██████ hazards");

    // Airport Terminal
    AddMessage("Security Alert: Metal detectors attract hordes within ██████ meters");
    AddMessage("Luggage Area: Conveyor systems transport survivors to ██████");
    AddMessage("Gate Warning: Jet bridges provide escape from ██████ special infected");
    AddMessage("Terminal Update: Duty-free shops contain rare ██████ supplies");
    AddMessage("Runway Alert: Landing lights attract massive horde from ██████");

    // Tank Behavior
    AddMessage("Combat Log: Tank now uses destroyed vehicles as ██████ shields");
    AddMessage("Rage Meter: Tank damage increases by ██████% when on fire");
    AddMessage("Tactical Update: Tank coordinates rock throws with ██████ attacks");
    AddMessage("Behavior Change: Tank prioritizes destroying ██████ escape routes");
    AddMessage("New Ability: Tank can now ██████ through certain walls");

    // Survivor Teamwork
    AddMessage("Team Action: Survivors can boost others to ██████ high places");
    AddMessage("Combo Move: Coordinated melee attacks stun ██████ for longer");
    AddMessage("Group Bonus: Healing efficiency increases near ██████ teammates");
    AddMessage("Team Tactic: Survivors can share ██████ during combat");
    AddMessage("Formation: Group movement speed increases when ██████ together");

        // Amusement Park
    AddMessage("Ride Alert: Roller coaster activation draws hordes from ██████");
    AddMessage("Park Update: Carousel music attracts special infected from ██████");
    AddMessage("Attraction Note: Ferris wheel can be used to ██████ between areas");
    AddMessage("Game Booth: Test of strength bell summons ██████ when rung");
    AddMessage("Park Warning: Cotton candy machines create ██████ visual cover");

    // Common Infected Evolution
    AddMessage("Mutation Note: Some commons now wear armor requiring ██████ to defeat");
    AddMessage("Horde Behavior: Infected climb on each other to reach ██████");
    AddMessage("Update: Hazmat infected immune to ██████ damage types");
    AddMessage("Alert: Construction worker infected can withstand ██████ headshots");
    AddMessage("New Strain: Riot gear infected must be attacked from ██████");

    // Weapon Modifications
    AddMessage("Mod Update: Shotgun spread can be adjusted using ██████");
    AddMessage("Attachment: Rifle grenade launcher unlocked after ██████");
    AddMessage("Custom Ammo: Electric shells effective against ██████ in water");
    AddMessage("Upgrade: Melee weapons can be enhanced with ██████");
    AddMessage("Modification: Silenced weapons attract less attention from ██████");

    // Forest Environment
    AddMessage("Nature Alert: Tree falls create new paths after ██████ damage");
    AddMessage("Wildlife: Disturbed birds reveal position of ██████");
    AddMessage("Forest Note: Poison ivy patches slow infected movement by ██████");
    AddMessage("Warning: Bear traps effective against ██████ special infected");
    AddMessage("Update: Dense foliage conceals approach of ██████");

        // Shopping Mall Events
    AddMessage("Store Alert: Toy store music box attracts Witch within ██████ seconds");
    AddMessage("Mall Radio: Emergency broadcast reveals safe path to ██████");
    AddMessage("Food Court: Walk-in freezer provides refuge from ██████ Tank");
    AddMessage("Security Room: CCTV system shows location of ██████ special infected");
    AddMessage("Escalator Warning: Power restoration triggers ██████ panic event");

    // Hunter Pack Behavior
    AddMessage("Pack Alert: Hunters now coordinate attacks with groups of ██████");
    AddMessage("Hunting Pattern: Alpha Hunter can command ██████ lesser Hunters");
    AddMessage("New Ability: Hunter pounce chain reaction possible with ██████");
    AddMessage("Pack Strategy: Hunters mark targets with ██████ for group attacks");
    AddMessage("Evolution: Hunter claws now cause ██████ damage over time");

    // Emergency Equipment
    AddMessage("First Aid: New trauma kit cures ██████ special infected effects");
    AddMessage("Defense Item: Riot shield blocks damage from ██████ directions");
    AddMessage("Emergency Gear: Flare gun marks extraction point for ██████");
    AddMessage("Equipment Drop: Military cache contains experimental ██████");
    AddMessage("Supply Update: Emergency radio calls support drop after ██████");

    // Sewer System
    AddMessage("Tunnel Warning: Toxic fumes cause ██████ damage without mask");
    AddMessage("Water Level: Rising water forces infected to ██████ higher ground");
    AddMessage("Echo Effect: Loud noises attract ██████ from connecting tunnels");
    AddMessage("Maintenance Room: Pump controls flood lower ██████ sections");
    AddMessage("Sewer Alert: Waste chemicals mutate infected into ██████");

        // Night Time Mechanics
    AddMessage("Darkness Alert: Special infected eyes now glow ██████ before attack");
    AddMessage("Vision Update: Flashlight beam attracts attention from ██████");
    AddMessage("Night Warning: Witch becomes more aggressive after ██████ sunset");
    AddMessage("Dark Zone: Survivors must maintain light source or suffer ██████");
    AddMessage("Night Vision: Battery packs last ██████ seconds before recharge");

    // Bridge Events
    AddMessage("Structure Alert: Bridge supports weaken after Tank deals ██████ damage");
    AddMessage("Warning: Bridge sway attracts nearby ██████ special infected");
    AddMessage("Cable Update: Zip lines allow quick escape from ██████");
    AddMessage("Bridge Control: Raising span creates ██████ minute panic event");
    AddMessage("Maintenance Path: Under-bridge passage reveals ██████ secret cache");

    // Fire Mechanics
    AddMessage("Flame Warning: Molotov fire spreads through ██████ infected groups");
    AddMessage("Heat Alert: Fire damage causes Tank to charge ██████ more often");
    AddMessage("Burn Effect: Flaming infected spread fire to ██████ on contact");
    AddMessage("Temperature: Heat causes gas station to explode after ██████");
    AddMessage("Fire Hazard: Burning buildings collapse following ██████ damage");

    // Office Building
    AddMessage("Security Desk: Card reader requires ██████ to access upper floors");
    AddMessage("Cubicle Warning: Office furniture creates maze that slows ██████");
    AddMessage("Server Room: Overheated servers attract ██████ special infected");
    AddMessage("Elevator Shaft: Emergency brake release causes ██████ chain event");
    AddMessage("Break Room: Coffee machine noise draws infected from ██████");

        // Boomer Tactics
    AddMessage("Bile Warning: New strain affects survivor vision for ██████ seconds");
    AddMessage("Explosion Range: Boomer blast now covers radius of ██████ meters");
    AddMessage("Horde Alert: Bile-covered survivors attract special infected after ██████");
    AddMessage("Mutation Note: Female Boomer bile causes infected to ██████ faster");
    AddMessage("Splash Effect: Bile now ricochets off walls to hit ██████");

    // Train Yard
    AddMessage("Railroad Alert: Moving trains create safe zones for ██████ seconds");
    AddMessage("Signal Warning: Train horn summons horde from ██████ direction");
    AddMessage("Cargo Update: Tanker cars explode after receiving ██████ damage");
    AddMessage("Track Switch: Redirecting trains crushes ██████ in their path");
    AddMessage("Container Area: Shipping crates contain emergency ██████ supplies");

    // Weather Effects
    AddMessage("Storm Warning: Lightning strikes ignite ██████ creating fire traps");
    AddMessage("Rain Update: Wet conditions reduce friction by ██████ percent");
    AddMessage("Fog Alert: Dense fog limits visibility to ██████ meters ahead");
    AddMessage("Wind Effect: Strong gusts affect throwing accuracy by ██████");
    AddMessage("Thunder Note: Loud storms mask approach of ██████ special infected");

    // Survivor Status
    AddMessage("Health System: Critical wounds reduce effectiveness of ██████");
    AddMessage("Stamina Alert: Running depletes energy after ██████ seconds");
    AddMessage("Team Bonus: Staying close heals ██████ damage over time");
    AddMessage("Status Effect: Pain pills delay infection for ██████ minutes");
    AddMessage("Condition Update: Limping survivors attract attention from ██████");

        // Carnival Area
    AddMessage("Attraction Alert: Shooting gallery noise attracts ██████ special infected");
    AddMessage("Ride Warning: Tunnel of Love provides safe passage past ██████");
    AddMessage("Game Stand: Ring toss bells trigger swarm from ██████ direction");
    AddMessage("Circus Tent: Clown infected drop ██████ when eliminated");
    AddMessage("Fun House: Mirror maze confuses infected for ██████ seconds");

    // Special Ammunition
    AddMessage("Ammo Type: Dragon's breath shells ignite ██████ on impact");
    AddMessage("Explosive Round: Frag bullets penetrate up to ██████ infected");
    AddMessage("Electric Ammo: Shock rounds chain between ██████ targets");
    AddMessage("Cryo Shells: Freeze ammunition slows infected for ██████ seconds");
    AddMessage("Custom Load: Armor piercing rounds effective against ██████");

    // Radio Communications
    AddMessage("Emergency Band: Military frequency reveals location of ██████");
    AddMessage("Radio Alert: Survivors can call for supply drops every ██████");
    AddMessage("Channel Update: Scanner picks up ██████ movement patterns");
    AddMessage("Broadcast: Emergency signal attracts rescue after ██████");
    AddMessage("Static Warning: Radio interference indicates nearby ██████");

    // Gas Station
    AddMessage("Fuel Alert: Gasoline trail creates ██████ meter fire wall");
    AddMessage("Pump Warning: Activation draws horde within ██████ seconds");
    AddMessage("Tank Note: Explosion damage increased by ██████ near pumps");
    AddMessage("Station Update: Store contains rare ██████ supplies");
    AddMessage("Hazard Zone: Gas leak creates toxic area for ██████");

        // Hotel Environment
    AddMessage("Elevator Warning: Power failure traps survivors for ██████ seconds");
    AddMessage("Room Service: Food carts can be used to block ██████ temporarily");
    AddMessage("Pool Area: Chlorine fumes stun infected for ██████ seconds");
    AddMessage("Kitchen Alert: Walk-in freezer provides sanctuary from ██████");
    AddMessage("Penthouse Note: Helipad access requires ██████ key cards");

    // Hunter Evolution
    AddMessage("Leap Update: Hunter can now chain pounce between ██████ targets");
    AddMessage("Claw Effect: Wounds now cause bleeding damage for ██████ seconds");
    AddMessage("Pack Behavior: Hunters mark targets with ██████ for group attacks");
    AddMessage("Night Vision: Improved tracking of survivors through ██████");
    AddMessage("Wall Jump: Hunter can rebound off ██████ surfaces during pursuit");

    // Survivor Gear
    AddMessage("Backpack Upgrade: Additional slot holds ██████ special items");
    AddMessage("Equipment Note: Riot shield blocks damage from ██████ direction");
    AddMessage("Gear Alert: Hazmat suit protects against ██████ damage types");
    AddMessage("Tool Belt: Quick-access items deploy ██████ faster");
    AddMessage("Armor Update: Kevlar vest reduces damage from ██████ attacks");

    // Church Area
    AddMessage("Bell Tower: Ringing summons mega horde after ██████ seconds");
    AddMessage("Holy Water: Blessed fountain slows infected for ██████ duration");
    AddMessage("Crypt Warning: Underground passage contains ██████ special infected");
    AddMessage("Organ Music: Playing attracts Witch to ██████ location");
    AddMessage("Confessional: Small spaces provide cover from ██████ attacks");

        // Helicopter Events
    AddMessage("Chopper Alert: Rescue vehicle arrives ██████ minutes after signal");
    AddMessage("Rotor Warning: Helicopter noise attracts ██████ special infected");
    AddMessage("Air Support: Gunship provides cover fire for ██████ seconds");
    AddMessage("Extraction Point: Landing zone must be cleared of ██████");
    AddMessage("Emergency Evac: Helicopter can carry maximum of ██████ survivors");

    // Smoker Mutations
    AddMessage("Range Update: Tongue now reaches ██████ meters when upgraded");
    AddMessage("Multi-Strike: Smoker can grab ██████ survivors simultaneously");
    AddMessage("Gas Cloud: Smoke screen disorients within ██████ meter radius");
    AddMessage("Constrict Effect: Captured survivors lose ██████ health per second");
    AddMessage("Evolution: Smoker now immune to ██████ damage while grabbing");

    // Library Setting
    AddMessage("Book Stack: Toppling shelves crush infected dealing ██████ damage");
    AddMessage("Quiet Zone: Noise attracts librarian Witch after ██████ seconds");
    AddMessage("Reading Room: Reference desk provides overview of ██████");
    AddMessage("Archive Access: Rare books reveal location of ██████");
    AddMessage("Study Area: Tables can be combined to block ██████ entrance");

    // Melee Weapons
    AddMessage("Katana Update: Blade now severs limbs causing ██████ damage");
    AddMessage("Chainsaw Fuel: Extended operation time of ██████ seconds");
    AddMessage("Baseball Bat: Home run swing launches infected ██████ meters");
    AddMessage("Fire Axe: Heavy attacks break through ██████ armor");
    AddMessage("Machete Strike: Quick slashes cause ██████ bleeding effect");

        // Zoo Environment
    AddMessage("Cage Warning: Lion enclosure contains ██████ unique infected");
    AddMessage("Monkey House: Primate infected can throw ██████ at survivors");
    AddMessage("Aquarium Area: Broken tanks create ██████ hazard zones");
    AddMessage("Elephant Yard: Large infected break through ██████ barriers");
    AddMessage("Petting Zoo: Infected animals attack in packs of ██████");

    // Tank Rage Mechanics
    AddMessage("Fury Alert: Tank damage increases by ██████% at critical health");
    AddMessage("Rage Meter: Consecutive hits build ██████ power multiplier");
    AddMessage("Berserk Mode: Tank gains immunity to ██████ after killing survivor");
    AddMessage("Rampage Update: Speed increases when ██████ survivors are nearby");
    AddMessage("Destruction: Enraged Tank can destroy ██████ with single hit");

    // Power Plant
    AddMessage("Reactor Warning: Radiation levels affect infected within ██████");
    AddMessage("Control Room: Emergency shutdown triggers ██████ minute event");
    AddMessage("Cooling Tower: Steam vents create ██████ second safe zones");
    AddMessage("Generator Alert: Power surge attracts ██████ special infected");
    AddMessage("Hazmat Zone: Contaminated areas require ██████ protection");

    // Survivor Abilities
    AddMessage("Skill Update: Perfect reloads grant ██████ seconds of critical hits");
    AddMessage("Team Move: Survivors can vault over ██████ using teammates");
    AddMessage("Combat Roll: Dodge special infected attacks for ██████ seconds");
    AddMessage("Quick Draw: Weapon swap speed increased by ██████ percent");
    AddMessage("Endurance: Sprint duration extended to ██████ when being chased");

        // Stadium Events
    AddMessage("Field Alert: Stadium lights attract hordes from ██████ sections");
    AddMessage("Scoreboard: Electronic display triggers ██████ special infected");
    AddMessage("Locker Room: Equipment cache contains rare ██████ supplies");
    AddMessage("Sound System: Speaker feedback stuns infected for ██████ seconds");
    AddMessage("VIP Suite: Private elevator requires ██████ access card");

    // Witch Variations
    AddMessage("Bride Witch: Wedding dress infected moves ██████% faster when startled");
    AddMessage("Nurse Witch: Medical variant can ██████ nearby infected");
    AddMessage("Wandering Witch: Patrols area searching for ██████");
    AddMessage("Screamer Witch: Cry attracts ██████ special infected types");
    AddMessage("Rage Pattern: Multiple Witches enter frenzy after ██████");

    // Construction Site Hazards
    AddMessage("Crane Warning: Swinging hook creates ██████ escape route");
    AddMessage("Cement Mixer: Fresh concrete slows infected by ██████%");
    AddMessage("Tool Shed: Power tools attract infected within ██████ meters");
    AddMessage("Scaffolding: Structure collapses after ██████ infected cross");
    AddMessage("Wrecking Ball: Impact creates shockwave affecting ██████");

    // Survivor Team Roles
    AddMessage("Medic Class: Healing efficiency increased by ██████ percent");
    AddMessage("Scout Role: Can mark special infected through ██████");
    AddMessage("Heavy Support: Carries additional ██████ for team");
    AddMessage("Demo Expert: Explosive damage increased by ██████");
    AddMessage("Team Leader: Nearby survivors gain ██████ bonus");

        // Prison Facility
    AddMessage("Cell Block: Riot infected immune to ██████ damage types");
    AddMessage("Guard Tower: Spotlight reveals infected within ██████ meters");
    AddMessage("Cafeteria: Food fight event attracts ██████ special infected");
    AddMessage("Solitary Wing: Confined spaces contain ██████ unique enemies");
    AddMessage("Security Room: Camera system tracks ██████ movement patterns");

    // Spitter Evolution
    AddMessage("Acid Pool: Corrosive damage increased by ██████ in water");
    AddMessage("Split Shot: Spitter can now target ██████ locations at once");
    AddMessage("Chemical Trail: Acid path remains active for ██████ seconds");
    AddMessage("Mutation: Acidic mist now affects visibility for ██████");
    AddMessage("Range Update: Projectile arc increased to ██████ meters");

    // Weather Hazards
    AddMessage("Storm Warning: Lightning strikes create ██████ fire zones");
    AddMessage("Flood Alert: Rising water forces route through ██████");
    AddMessage("Tornado Watch: Flying debris damages both ██████ and infected");
    AddMessage("Blizzard Note: Snow reduces movement speed by ██████");
    AddMessage("Heat Wave: Stamina depletes ██████% faster outdoors");

    // Military Checkpoint
    AddMessage("Defense Line: Automated turret targets ██████ special infected");
    AddMessage("Bunker Alert: Safe room contains experimental ██████");
    AddMessage("Radio Tower: Signal calls artillery strike on ██████");
    AddMessage("Barricade: Tank damage reduced by ██████ at fortified points");
    AddMessage("Evacuation: Rescue vehicle arrives after ██████ waves");

        // Subway Station
    AddMessage("Train Alert: Passing subway creates safe zone for ██████ seconds");
    AddMessage("Power Rail: Electric tracks instantly kill ██████ infected types");
    AddMessage("Platform Warning: Overcrowded areas collapse after ██████");
    AddMessage("Tunnel Vision: Emergency lights reveal ██████ special infected");
    AddMessage("Station Control: PA system can redirect ██████ to other areas");

    // Jockey Pack Behavior
    AddMessage("Group Tactics: Jockeys now coordinate to lead victims toward ██████");
    AddMessage("Pack Leader: Alpha Jockey can command ██████ others");
    AddMessage("Ride Duration: Control time extended near ██████ hazards");
    AddMessage("Jump Chain: Jockeys can leap between ██████ survivors");
    AddMessage("Evolution: Enhanced grip prevents release for ██████ seconds");

    // Beach Location
    AddMessage("Pier Warning: Wooden planks break after ██████ infected cross");
    AddMessage("Lifeguard Tower: Provides overview of ██████ approaching hordes");
    AddMessage("Surf Zone: Water slows infected movement by ██████ percent");
    AddMessage("Beach Party: Music attracts special infected from ██████");
    AddMessage("Lighthouse: Beacon activation triggers ██████ minute event");

    // Survivor Equipment
    AddMessage("Tactical Vest: Additional storage for ██████ special items");
    AddMessage("Helmet Upgrade: Headshot protection from ██████ attacks");
    AddMessage("Boot Mod: Kick attack knocks back ██████ common infected");
    AddMessage("Arm Guard: Reduces damage while ██████ special infected");
    AddMessage("Emergency Pack: Quick-deploy items within ██████ seconds");

        // Shopping Center
    AddMessage("Escalator Alert: Moving stairs create ██████ temporary escape route");
    AddMessage("Toy Store: Musical displays attract Witch within ██████ seconds");
    AddMessage("Food Court: Microwave beeping summons ██████ special infected");
    AddMessage("Sports Shop: Athletic equipment can be used as ██████ weapons");
    AddMessage("Security Gate: Metal shutters hold for ██████ against Tank");

    // Hunter Advanced Tactics
    AddMessage("Wall Run: Hunter can now traverse ██████ vertical surfaces");
    AddMessage("Pack Strike: Coordinated pounce with ██████ other Hunters");
    AddMessage("Stealth Mode: Crouching Hunter invisible to ██████ detection");
    AddMessage("Leap Chain: Multiple jumps before ██████ second cooldown");
    AddMessage("Claw Evolution: Attacks now cause ██████ damage over time");

    // Carnival Rides
    AddMessage("Roller Coaster: Activation creates ██████ minute panic event");
    AddMessage("Ferris Wheel: Lights attract infected from ██████ zones");
    AddMessage("Carousel: Music draws special infected within ██████ meters");
    AddMessage("Haunted House: Dark ride contains ██████ unique enemies");
    AddMessage("Bumper Cars: Electric grid stuns infected for ██████ seconds");

    // Advanced Ammunition
    AddMessage("Hollow Point: Bullets cause ██████ bleeding damage");
    AddMessage("Incendiary Round: Fire spreads to ██████ nearby infected");
    AddMessage("EMP Shell: Discharge disrupts ██████ special abilities");
    AddMessage("Cryo Ammo: Frozen targets shatter after ██████ hits");
    AddMessage("Smart Bullets: Rounds track ██████ marked targets");

        // Airport Terminal
    AddMessage("Baggage Claim: Conveyor system crushes ██████ pursuing infected");
    AddMessage("Security Gate: Metal detector alerts trigger ██████ special infected");
    AddMessage("Duty Free: Alcohol bottles create temporary ██████ fire zones");
    AddMessage("Control Tower: Radio contact reveals ██████ escape routes");
    AddMessage("Runway Alert: Landing lights attract hordes from ██████ miles");

    // Tank Variations
    AddMessage("Armored Tank: Reinforced specimen requires ██████ hits to weaken");
    AddMessage("Toxic Tank: Releases spores affecting ██████ meter radius");
    AddMessage("Berserker: Rage mode activated at ██████ health remaining");
    AddMessage("Demolisher: Can throw ██████ pieces of environment");
    AddMessage("Alpha Tank: Commands lesser Tanks within ██████ range");

    // Emergency Equipment
    AddMessage("Defibrillator: Now revives victims within ██████ minutes");
    AddMessage("Adrenaline Shot: Temporary immunity to ██████ damage types");
    AddMessage("First Aid Plus: Advanced kit heals ██████ additional health");
    AddMessage("Emergency Radio: Calls support drop every ██████ minutes");
    AddMessage("Flare Gun: Marks extraction point visible from ██████");

    // Sewer System
    AddMessage("Maintenance Tunnel: Flooded sections contain ██████ mutated infected");
    AddMessage("Gas Warning: Toxic fumes require ██████ protective gear");
    AddMessage("Water Level: Rising flood creates ██████ minute escape timer");
    AddMessage("Echo Effect: Loud noises attract ██████ from connected tunnels");
    AddMessage("Chemical Hazard: Waste exposure causes ██████ damage per second");

        // Office Building
    AddMessage("Elevator Shaft: Emergency drop creates ██████ second escape route");
    AddMessage("Server Room: Overheating computers attract ██████ special infected");
    AddMessage("Cubicle Maze: Collapsed workspaces slow infected by ██████");
    AddMessage("Break Room: Coffee machine noise draws hordes from ██████");
    AddMessage("Executive Suite: Panic room holds out for ██████ minutes");

    // Boomer Strategies
    AddMessage("Bile Bomb: Enhanced formula attracts infected for ██████ seconds");
    AddMessage("Splash Zone: Explosion radius increased to ██████ meters");
    AddMessage("Chain Reaction: Bile affects ██████ nearby survivors");
    AddMessage("Lingering Effect: Bile mist remains active for ██████ duration");
    AddMessage("Mutation: Bile now corrodes armor over ██████ seconds");

    // Power Station
    AddMessage("Generator Room: Activation sequence draws ██████ Tank variant");
    AddMessage("High Voltage: Electric arcs eliminate ██████ infected instantly");
    AddMessage("Control Panel: Emergency shutdown affects ██████ city blocks");
    AddMessage("Transformer: Explosion creates chain reaction within ██████");
    AddMessage("Power Grid: Restored electricity activates ██████ defense systems");

    // Survivor Perks
    AddMessage("Quick Draw: Weapon swap speed increased by ██████ percent");
    AddMessage("Marathon: Stamina regenerates ██████ faster while moving");
    AddMessage("Medic: Healing items used ██████ more efficiently");
    AddMessage("Demolition: Explosive radius increased by ██████ meters");
    AddMessage("Marksman: Headshot streak grants ██████ damage bonus");

        // Hospital Wing
    AddMessage("Operating Room: Surgical tools provide ██████ instant kills");
    AddMessage("Quarantine Zone: Hazmat infected immune to ██████ damage");
    AddMessage("Medical Storage: Rare supplies restore ██████ bonus health");
    AddMessage("Morgue Alert: Cold storage contains ██████ unique infected");
    AddMessage("ICU Warning: Life support beeping attracts ██████ within seconds");

    // Smoker Adaptations
    AddMessage("Tongue Grip: Constriction damage increased by ██████ percent");
    AddMessage("Multi-Target: Can now grab ██████ survivors simultaneously");
    AddMessage("Smoke Screen: Dense cloud reduces accuracy by ██████");
    AddMessage("Quick Strike: Tongue retracts ██████ faster after upgrade");
    AddMessage("Evolution: Can now pull victims through ██████ obstacles");

    // Warehouse District
    AddMessage("Forklift: Vehicle horn triggers ██████ special infected spawn");
    AddMessage("Loading Dock: Cargo containers provide ██████ defensive positions");
    AddMessage("Storage Racks: Collapsing shelves eliminate ██████ infected");
    AddMessage("Chemical Spill: Hazard zone deals ██████ damage per second");
    AddMessage("Shipping Area: Container maze leads to ██████ secret cache");

    // Weather Impact
    AddMessage("Thunder Storm: Lightning reveals ██████ special infected positions");
    AddMessage("Heavy Rain: Reduced visibility within ██████ meters");
    AddMessage("Wind Warning: Strong gusts affect ██████ projectile accuracy");
    AddMessage("Fog Bank: Dense coverage conceals approach of ██████");
    AddMessage("Temperature Drop: Freezing conditions slow infected by ██████");

        // Fire Station
    AddMessage("Alarm Bell: Station alert summons ██████ special infected");
    AddMessage("Fire Pole: Quick descent creates ██████ second vulnerability");
    AddMessage("Truck Bay: Emergency vehicle provides ██████ mobile cover");
    AddMessage("Water Cannon: High pressure stream pushes back ██████");
    AddMessage("Equipment Room: Firefighter gear resists ██████ damage type");

    // Charger Mutations
    AddMessage("Impact Force: Wall slam now affects ██████ nearby survivors");
    AddMessage("Armor Plating: Requires ██████ hits to stagger");
    AddMessage("Charge Path: Creates shockwave affecting ██████ meter radius");
    AddMessage("Quick Recovery: Reduced cooldown by ██████ after miss");
    AddMessage("Evolution: Can now charge through ██████ destructible walls");

    // Movie Theater
    AddMessage("Projection Room: Spotlight reveals ██████ approaching hordes");
    AddMessage("Screen Warning: Movie audio attracts infected from ██████");
    AddMessage("Concession Area: Popcorn machine noise draws ██████");
    AddMessage("Emergency Exit: Alarm triggers ██████ minute panic event");
    AddMessage("Theater Seating: Tight rows slow infected by ██████");

    // Advanced Weapons
    AddMessage("Compound Bow: Silent kills attract no ██████ attention");
    AddMessage("Nail Gun: Rapid fire pins infected to ██████ surfaces");
    AddMessage("Tesla Coil: Electric discharge chains through ██████");
    AddMessage("Freeze Ray: Crystallizes infected for ██████ seconds");
    AddMessage("Flame Thrower: Creates fire barrier lasting ██████");

        // Cruise Ship
    AddMessage("Engine Room: Overload sequence attracts ██████ Tank variant");
    AddMessage("Pool Deck: Chlorine gas stuns infected for ██████ seconds");
    AddMessage("Ballroom: Chandelier drop eliminates ██████ infected below");
    AddMessage("Casino Area: Slot machine sounds trigger ██████ special infected");
    AddMessage("Bridge Alert: Horn blast summons hordes within ██████ miles");

    // Witch Behaviors
    AddMessage("Stalker Mode: Witch follows survivor groups for ██████ meters");
    AddMessage("Rage Chain: Startled Witch alerts others within ██████ range");
    AddMessage("Dark Hunter: Witch more aggressive in shadows after ██████");
    AddMessage("Sound Trigger: Music causes instant ██████ state change");
    AddMessage("Pack Mentality: Multiple Witches coordinate ██████ attacks");

    // Underground Lab
    AddMessage("Test Chamber: Specimen ██████ escaped containment level 4");
    AddMessage("Research Wing: Experimental cure provides ██████ immunity");
    AddMessage("Biohazard: Contaminated zone requires ██████ protection");
    AddMessage("Security Lock: Breach releases ██████ enhanced infected");
    AddMessage("Data Center: Computer records reveal ██████ mutation source");

    // Team Mechanics
    AddMessage("Formation Bonus: Grouped survivors deal ██████ extra damage");
    AddMessage("Rescue Timer: Revive speed increased by ██████ with helpers");
    AddMessage("Supply Share: Items automatically split between ██████");
    AddMessage("Combat Synergy: Coordinated fire creates ██████ damage bonus");
    AddMessage("Defense Pattern: Circular formation repels ██████ attacks");

        // Amusement Park
    AddMessage("Roller Coaster: Track collapse creates ██████ escape sequence");
    AddMessage("House of Mirrors: Reflections confuse infected for ██████");
    AddMessage("Carousel Music: Attracts special infected from ██████ zones");
    AddMessage("Cotton Candy: Sugar fire creates ██████ second distraction");
    AddMessage("Ferris Wheel: Emergency stop triggers ██████ minute event");

    // Hunter Elite
    AddMessage("Alpha Pounce: Leadership ability affects ██████ nearby Hunters");
    AddMessage("Stealth Mode: Becomes invisible for ██████ seconds while still");
    AddMessage("Wall Strike: Can bounce between ██████ surfaces before attack");
    AddMessage("Pack Signal: Howl summons ██████ additional Hunters");
    AddMessage("Death Mark: Claw wounds track target for ██████ seconds");

    // Military Base
    AddMessage("Armory Access: Weapon cache requires ██████ security codes");
    AddMessage("Radar Room: Scanner reveals ██████ special infected positions");
    AddMessage("Missile Silo: Launch sequence attracts ██████ Tank variant");
    AddMessage("Barracks: Sleeping quarters contain ██████ unique infected");
    AddMessage("Command Center: Radio calls ██████ air support strikes");

    // Environmental Hazards
    AddMessage("Chemical Spill: Toxic puddles cause ██████ damage per second");
    AddMessage("Live Wire: Broken cables electrify ██████ meter radius");
    AddMessage("Gas Leak: Explosive fumes detonate after ██████ gunshots");
    AddMessage("Steam Pipe: Burst valves create ██████ second barriers");
    AddMessage("Quicksand: Mud pits trap infected for ██████ duration");

        // Zoo Exhibits
    AddMessage("Lion Den: Infected big cats leap ██████ meters to attack");
    AddMessage("Snake House: Reptile infected can climb ██████ surfaces");
    AddMessage("Gorilla Cage: Primate infected throw ██████ at survivors");
    AddMessage("Aviary: Infected birds dive bomb from ██████ meters high");
    AddMessage("Elephant House: Massive infected break through ██████ walls");

    // Spitter Tactics
    AddMessage("Acid Rain: Overhead spit creates ██████ meter damage zone");
    AddMessage("Chemical Mix: Acid pools combine for ██████ damage boost");
    AddMessage("Corrosive Mist: Acid vapor reduces visibility by ██████");
    AddMessage("Split Shot: Can target ██████ locations simultaneously");
    AddMessage("Mutation: Acid now melts through ██████ level surfaces");

    // Train Station
    AddMessage("Control Room: Signal change redirects ██████ approaching horde");
    AddMessage("Cargo Hold: Hazmat containers release ██████ when damaged");
    AddMessage("Platform Edge: Live rail eliminates ██████ infected instantly");
    AddMessage("Ticket Hall: Turnstiles create ██████ defensive chokepoint");
    AddMessage("Maintenance Tunnel: Service route bypasses ██████ infected");

    // Survivor Skills
    AddMessage("Parkour: Wall running available for ██████ seconds");
    AddMessage("Sixth Sense: Detect special infected within ██████ meters");
    AddMessage("Combat Roll: Dodge specials with ██████ success rate");
    AddMessage("Quick Hands: Reload speed increased by ██████ percent");
    AddMessage("Adrenaline Rush: Critical health boosts damage by ██████");

        // Nuclear Plant
    AddMessage("Reactor Core: Radiation levels affect infected within ██████");
    AddMessage("Cooling Tower: Steam vents provide ██████ second escape route");
    AddMessage("Control Panel: Meltdown sequence attracts ██████ special infected");
    AddMessage("Hazmat Zone: Contaminated areas mutate ██████ common infected");
    AddMessage("Emergency Seal: Containment doors close after ██████ minutes");

    // Boomer Family
    AddMessage("Bile Father: Massive explosion covers ██████ meter radius");
    AddMessage("Acid Mother: Bile now corrodes armor for ██████ seconds");
    AddMessage("Twin Boomers: Synchronized explosion affects ██████ areas");
    AddMessage("Bile Child: Quick movement but ██████ explosion radius");
    AddMessage("Elder Boomer: Bile attracts ██████ special infected types");

    // Church Interior
    AddMessage("Bell Tower: Ringing summons ██████ wave mega horde");
    AddMessage("Pipe Organ: Music attracts Witch within ██████ seconds");
    AddMessage("Confessional: Small spaces provide ██████ temporary safety");
    AddMessage("Stained Glass: Broken windows create ██████ entry points");
    AddMessage("Crypt Access: Underground passage contains ██████ rare items");

    // Combat Mechanics
    AddMessage("Friendly Fire: Team damage reduced by ██████ when crouching");
    AddMessage("Melee Chain: Consecutive strikes increase damage by ██████");
    AddMessage("Precision Shot: Headshots mark target for ██████ seconds");
    AddMessage("Cover System: Reduced damage while behind ██████ objects");
    AddMessage("Combat Focus: Perfect reload grants ██████ critical hits");

        // Water Park
    AddMessage("Wave Pool: Current pushes infected back ██████ meters");
    AddMessage("Water Slide: High-speed escape reduces ██████ damage");
    AddMessage("Lazy River: Flow direction changes every ██████ seconds");
    AddMessage("Splash Pad: Water jets stun infected for ██████ duration");
    AddMessage("Diving Platform: Height advantage reveals ██████ spawns");

    // Tank Commander
    AddMessage("Alpha Strain: Can direct ██████ lesser Tanks in combat");
    AddMessage("Battle Cry: Enrages nearby infected within ██████ meters");
    AddMessage("War Path: Destroys environment to create ██████ shortcuts");
    AddMessage("Tactical Mind: Predicts survivor movement after ██████");
    AddMessage("Command Post: Calls hordes from ██████ different directions");

    // Sports Arena
    AddMessage("Stadium Lights: Activation draws infected from ██████ miles");
    AddMessage("Score Board: Electronic display triggers ██████ special spawn");
    AddMessage("Team Lockers: Equipment rooms contain ██████ rare weapons");
    AddMessage("Field Sprinklers: Create slick surface for ██████ seconds");
    AddMessage("Announcer Booth: PA system can redirect ██████ horde path");

    // Survivor Gear
    AddMessage("Tactical Vest: Reduces special infected damage by ██████");
    AddMessage("Climbing Gear: Allows vertical escape within ██████ seconds");
    AddMessage("Night Vision: Reveals infected movement through ██████");
    AddMessage("Riot Shield: Blocks damage from ██████ different angles");
    AddMessage("Grapple Gun: Quick escape to heights under ██████ meters");

        // Convention Center
    AddMessage("Main Hall: Costumed infected deal ██████ bonus damage");
    AddMessage("Gaming Area: Electronic noise attracts ██████ special infected");
    AddMessage("Comic Section: Cardboard standees confuse infected for ██████");
    AddMessage("Vendor Hall: Merchandise booths create ██████ escape maze");
    AddMessage("Stage Show: Lighting effects stun infected for ██████ seconds");

    // Jockey Evolution
    AddMessage("Mind Link: Can sense other survivors within ██████ meters");
    AddMessage("Jump Chain: Leaps between victims after ██████ seconds");
    AddMessage("Puppet Master: Extended control duration of ██████");
    AddMessage("Hive Mind: Coordinates attacks with ██████ other specials");
    AddMessage("Neural Hack: Temporarily disables victim's ██████ ability");

    // Subway Tunnels
    AddMessage("Power Rails: Electric track eliminates ██████ infected instantly");
    AddMessage("Echo Location: Sound attracts hordes from ██████ stations");
    AddMessage("Service Path: Maintenance tunnels bypass ██████ infected zones");
    AddMessage("Train Impact: Moving cars create ██████ second safe passage");
    AddMessage("Signal Room: Control panel redirects ██████ approaching threats");

    // Advanced Combat
    AddMessage("Chain Attack: Melee kills boost damage by ██████ percent");
    AddMessage("Precision Aim: Consecutive headshots mark ██████ targets");
    AddMessage("Team Synergy: Nearby survivors share ██████ damage bonus");
    AddMessage("Combat Flow: Perfect reloads grant ██████ temporary speed");
    AddMessage("Battle Focus: Kill streaks reveal ██████ special infected");

        // Ice Rink
    AddMessage("Frozen Surface: Infected slip and fall for ██████ seconds");
    AddMessage("Zamboni: Vehicle noise attracts ██████ special infected");
    AddMessage("Hockey Gear: Sports equipment provides ██████ protection");
    AddMessage("Score Horn: Sound blast stuns infected within ██████ meters");
    AddMessage("Penalty Box: Small area provides ██████ second safe zone");

    // Witch Queen
    AddMessage("Royal Guard: Commands ██████ regular Witches in area");
    AddMessage("Death Scream: Cry paralyzes survivors for ██████ seconds");
    AddMessage("Dark Court: Spawns ██████ Witch minions when threatened");
    AddMessage("Shadow Walk: Teleports through ██████ to pursue targets");
    AddMessage("Rage Aura: Nearby Witches enter frenzy after ██████");

    // Power Plant
    AddMessage("Reactor Warning: Radiation mutates infected within ██████");
    AddMessage("Steam Burst: Pressure vents create ██████ meter safe zone");
    AddMessage("Control Room: Shutdown sequence attracts ██████ Tank variant");
    AddMessage("Cooling Tower: Toxic water deals ██████ damage per second");
    AddMessage("Generator: Power surge electrifies ██████ nearby surfaces");

    // Survivor Tactics
    AddMessage("Quick Step: Dodge special infected with ██████ success rate");
    AddMessage("Team Cover: Crouching behind allies reduces damage by ██████");
    AddMessage("Battle Sense: Detect approaching hordes within ██████ meters");
    AddMessage("Ammo Share: Pass ammunition within ██████ meter radius");
    AddMessage("Rally Point: Group healing speed increased by ██████");

        // Ski Resort
    AddMessage("Ski Lift: Cable car provides escape from ██████ pursuing hordes");
    AddMessage("Snow Storm: Reduced visibility beyond ██████ meters");
    AddMessage("Lodge Fire: Burning building attracts ██████ special infected");
    AddMessage("Avalanche: Snow slide eliminates ██████ infected in path");
    AddMessage("Ice Cave: Frozen infected break free after ██████ seconds");

    // Smoker Commander
    AddMessage("Tactical Grab: Can coordinate ██████ tongue attacks at once");
    AddMessage("Smoke Signal: Calls ██████ special infected to location");
    AddMessage("Chain Reaction: Tongue pulls trigger ██████ trap sequence");
    AddMessage("Smoke Screen: Dense cloud blinds survivors for ██████");
    AddMessage("Master Strike: Can pull victims through ██████ obstacles");

    // Casino Floor
    AddMessage("Slot Machines: Jackpot noise attracts ██████ infected types");
    AddMessage("Security Room: Camera system reveals ██████ special spawns");
    AddMessage("Poker Tables: Chips create slippery surface for ██████");
    AddMessage("Vault Access: Safe room contains ██████ unique weapons");
    AddMessage("Show Stage: Performance lights blind infected for ██████");

    // Combat Upgrades
    AddMessage("Weapon Sync: Team using same guns deal ██████ bonus damage");
    AddMessage("Perfect Timing: Precise reloads grant ██████ critical hits");
    AddMessage("Battle Flow: Kill streaks increase speed by ██████ percent");
    AddMessage("Team Focus: Marked targets take ██████ additional damage");
    AddMessage("Combat Medic: Healing items used ██████ faster in combat");

        // Abandoned Mine
    AddMessage("Cave In: Collapsing tunnel crushes ██████ infected below");
    AddMessage("Mine Cart: Moving vehicle attracts ██████ special infected");
    AddMessage("Gas Pocket: Methane explosion affects ██████ meter radius");
    AddMessage("Deep Shaft: Elevator noise echoes for ██████ miles");
    AddMessage("Dark Zone: Headlamps reveal ██████ stalking infected");

    // Tank Berserker
    AddMessage("Blood Rage: Damage increases by ██████ at low health");
    AddMessage("Ground Slam: Shockwave knocks back ██████ meter radius");
    AddMessage("Fury Chain: Consecutive hits boost speed by ██████");
    AddMessage("Battle Cry: Enrages nearby infected within ██████");
    AddMessage("Death Charge: Final attack deals ██████ massive damage");

    // Carnival Horror
    AddMessage("Clown Car: Honking attracts ██████ special infected");
    AddMessage("Fun House: Mirror maze confuses infected for ██████");
    AddMessage("Ring Toss: Bell noise summons Witch after ██████");
    AddMessage("Cotton Candy: Sugar fire creates ██████ damage zone");
    AddMessage("Ticket Booth: Safe room holds against Tank for ██████");

    // Emergency Equipment
    AddMessage("Flare Gun: Signal marks extraction point for ██████");
    AddMessage("Riot Shield: Blocks damage from ██████ different angles");
    AddMessage("Trauma Kit: Advanced healing restores ██████ health");
    AddMessage("Radio Beacon: Calls support drop every ██████ minutes");
    AddMessage("Glow Sticks: Mark safe paths through ██████ dark areas");

        // Research Facility
    AddMessage("Test Chamber: Failed experiment released ██████ new strain");
    AddMessage("Bio Lab: Containment breach affects ██████ security zones");
    AddMessage("Specimen Storage: Cryo units contain ██████ frozen infected");
    AddMessage("Clean Room: Decontamination cycle takes ██████ seconds");
    AddMessage("Data Center: Computer logs reveal ██████ mutation source");

    // Hunter Pack Alpha
    AddMessage("Pack Leader: Commands up to ██████ lesser Hunters");
    AddMessage("Silent Stalk: Pack becomes invisible for ██████ seconds");
    AddMessage("Group Pounce: Coordinated attack from ██████ directions");
    AddMessage("Hunt Call: Howl reveals survivor positions for ██████");
    AddMessage("Pack Fury: Each kill increases damage by ██████ percent");

    // Sewage Treatment
    AddMessage("Toxic Pool: Chemical waste creates ██████ damage zone");
    AddMessage("Pump Station: Activation floods lower levels for ██████");
    AddMessage("Gas Leak: Methane explosion radius of ██████ meters");
    AddMessage("Filter Room: Toxic fumes require ██████ protective gear");
    AddMessage("Waste Canal: Current moves at ██████ meters per second");

    // Survivor Synergy
    AddMessage("Team Spirit: Nearby allies gain ██████ damage boost");
    AddMessage("Group Heal: Medkits affect survivors within ██████");
    AddMessage("Unity Bonus: Coordinated fire increases damage by ██████");
    AddMessage("Shared Focus: Marked targets visible to team for ██████");
    AddMessage("Rally Effect: Group movement speed up by ██████ percent");

        // Lumber Mill
    AddMessage("Saw Blade: Active machinery attracts ██████ special infected");
    AddMessage("Timber Fall: Falling trees crush ██████ infected in path");
    AddMessage("Wood Chipper: Machine noise draws hordes from ██████");
    AddMessage("Log Jam: River blockage creates ██████ temporary bridge");
    AddMessage("Crane Control: Moving logs eliminate ██████ infected below");

    // Spitter Queen
    AddMessage("Acid Storm: Creates toxic rain covering ██████ meters");
    AddMessage("Royal Bile: Corrosive pool lasts for ██████ seconds");
    AddMessage("Spawn Pods: Acid cocoons release ██████ spitter minions");
    AddMessage("Chemical Mist: Acid cloud reduces vision by ██████");
    AddMessage("Evolution: Can now melt through ██████ level barriers");

    // Airport Terminal
    AddMessage("Luggage Claim: Conveyor creates ██████ escape route");
    AddMessage("Security Gate: Metal detector alerts ██████ special infected");
    AddMessage("Duty Free: Alcohol bottles create ██████ fire hazard");
    AddMessage("Gate Display: Electronic board attracts ██████ from gates");
    AddMessage("Runway Alert: Landing lights visible from ██████ miles");

    // Combat Mechanics
    AddMessage("Perfect Timing: Precise reload grants ██████ critical hits");
    AddMessage("Chain Strike: Melee kills boost damage by ██████");
    AddMessage("Focus Fire: Marked targets take ██████ bonus damage");
    AddMessage("Battle Flow: Kill streak increases speed for ██████");
    AddMessage("Team Synergy: Nearby allies share ██████ damage bonus");

        // Cruise Ship
    AddMessage("Engine Room: Overheating core attracts ██████ Tank variant");
    AddMessage("Ballroom: Chandelier drop eliminates ██████ infected below");
    AddMessage("Pool Deck: Chlorine gas stuns infected for ██████ seconds");
    AddMessage("Bridge Alert: Ship horn summons hordes within ██████ miles");
    AddMessage("Casino Floor: Slot machines trigger ██████ special infected");

    // Charger Elite
    AddMessage("Rampage Mode: Chain charges through ██████ survivors");
    AddMessage("Impact Force: Wall slam affects ██████ meter radius");
    AddMessage("Armor Plating: Requires ██████ hits to stagger");
    AddMessage("Ground Pound: Slam creates shockwave stunning ██████");
    AddMessage("Battle Rush: Each hit increases speed by ██████ percent");

    // Weather System
    AddMessage("Lightning Strike: Electric bolt chains through ██████");
    AddMessage("Heavy Rain: Reduces visibility to ██████ meters");
    AddMessage("Wind Gust: Affects projectile accuracy by ██████");
    AddMessage("Fog Bank: Conceals special infected within ██████");
    AddMessage("Storm Warning: Thunder masks approach of ██████");

    // Military Bunker
    AddMessage("Armory: Weapon cache requires ██████ access codes");
    AddMessage("War Room: Radar reveals infected within ██████ range");
    AddMessage("Defense Grid: Automated turrets target ██████ types");
    AddMessage("Blast Door: Holds against Tank damage for ██████");
    AddMessage("Command Center: Radio calls ██████ air support");

        // Final Stand Location
    AddMessage("Last Defense: Military base holds final cure in ██████");
    AddMessage("Evacuation Zone: Rescue vehicle arrives in ██████ minutes");
    AddMessage("Command Post: Satellite reveals horde movement from ██████");
    AddMessage("Final Battle: Mega Tank approaches from ██████ direction");
    AddMessage("Hope Remains: Experimental weapon requires ██████ to charge");

    // Ultimate Tank
    AddMessage("Mutation Omega: Evolved Tank commands army of ██████");
    AddMessage("Final Form: Regenerates ██████ health per second");
    AddMessage("Death Charge: Ultimate attack destroys ██████ structures");
    AddMessage("Rage Mode: Damage increases by ██████% at critical health");
    AddMessage("Last Stand: Sacrificial explosion affects ██████ meter radius");

    // Emergency Protocol
    AddMessage("Final Warning: Nuclear option activated in ██████ minutes");
    AddMessage("Last Resort: Helicopter extracts survivors after ██████");
    AddMessage("Critical Alert: Facility self-destructs in ██████ seconds");
    AddMessage("Final Hope: Experimental cure protects for ██████ hours");
    AddMessage("Last Message: Military bombs city in ██████ minutes");

    // Survivor's Last Stand
    AddMessage("Final Gear: Ultimate weapons unlock after ██████ waves");
    AddMessage("Last Defense: Team damage boosted by ██████ percent");
    AddMessage("Ultimate Sacrifice: Fallen survivors become ██████");
    AddMessage("Final Push: Adrenaline boost lasts ██████ seconds");
    AddMessage("Last Hope: Survival chance increased by ██████ percent");
}

void SendLeakMessage(const char[] message) {
    char buffer[MAX_MESSAGE_LENGTH];
    Format(buffer, sizeof(buffer), "[L4D3 LEAK]\n%s", message);
    
    // Send to everyone in game
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i)) {
            PrintHintText(i, "%s", buffer);
        }
    }
    
    PrintToServer("[L4D3 Leaks] Sent message: %s", message);
}

public void OnClientPostAdminCheck(int client) {
    // Reset vote status initially
    g_HasVoted[client] = false;
    g_bFirstJoin[client] = true;
    
    // Check if it's a real player
    if (!IsFakeClient(client)) {
        char steamId[64];
        if (GetClientAuthId(client, AuthId_Steam3, steamId, sizeof(steamId), true)) {
            // Clean up Steam ID for filename
            ReplaceString(steamId, sizeof(steamId), "[", "");
            ReplaceString(steamId, sizeof(steamId), "]", "");
            ReplaceString(steamId, sizeof(steamId), ":", "");
            ReplaceString(steamId, sizeof(steamId), "U", "u");
            
            char filePath[PLATFORM_MAX_PATH];
            BuildPath(Path_SM, filePath, sizeof(filePath), "data/l4d3_votes/%s.kv", steamId);
            
            KeyValues kv = new KeyValues("PlayerVote");
            if (kv.ImportFromFile(filePath)) {
                // Restore their vote
                char category[32], vote[32];
                kv.GetString("category", category, sizeof(category));
                kv.GetString("vote", vote, sizeof(vote));
                g_HasVoted[client] = true;
                g_bFirstJoin[client] = false;
                
                Format(g_PlayerVotes[client], sizeof(g_PlayerVotes[]), "%s_%s", category, vote);
                
                PrintToServer("[DEBUG] Loaded vote from file: %s", filePath);
                
                // Inform player their vote was restored
                PrintToChat(client, "\x04[VALVE]\x01 ═══════════════════════");
                PrintToChat(client, "\x04[VALVE]\x01 Your previous vote has been restored!");
                PrintToChat(client, "\x04[VALVE]\x01 Type \x05!resetvote\x01 to vote again.");
                PrintToChat(client, "\x04[VALVE]\x01 ═══════════════════════");
            } else {
                // Only show menu to new players who haven't voted before
                CreateTimer(10.0, Timer_ShowMenu, GetClientUserId(client));
            }
            delete kv;
        }
    }
}

public Action Timer_DelayedStart(Handle timer) {
    if (g_hEnabled.BoolValue) {
        CreateMessageTimer();
    }
    return Plugin_Stop;
}

public Action Timer_CheckTimerAfterJoin(Handle timer) {
    // Check if ConVar handle is valid before using it
    if (g_hLeakMessagesEnabled == null) {
        return Plugin_Stop;
    }

    // Check if messages are enabled
    if (g_hLeakMessagesEnabled.BoolValue) {
        // Create timer if it doesn't exist
        if (g_hTimer == null) {
            CreateMessageTimer();
            PrintToServer("[L4D3 Leaks] Timer recreated after player join");
        }
    }
    
    return Plugin_Stop;
}

void StartHacking(int client) {
    g_bPlayerHacking[client] = true;
    g_iHackProgress[client] = 0;
    g_fNextHackTime[client] = GetGameTime() + 5.0;
    
    PrintToChat(client, "\x04[SYSTEM]\x01 ╔════════════════════════════");
    PrintToChat(client, "\x04[SYSTEM]\x01 ║ INITIATING LEVEL %d INTRUSION", g_iHackDifficulty[client]);
    PrintToChat(client, "\x04[SYSTEM]\x01 ║ Target: L4D3 Development Server");
    PrintToChat(client, "\x04[SYSTEM]\x01 ║ Status: CONNECTING...");
    PrintToChat(client, "\x04[SYSTEM]\x01 ╚════════════════════════════");
    
    switch(g_iHackDifficulty[client]) {
        case 1: {
            PrintToChat(client, "\x04[SYSTEM]\x01 ► Basic security detected");
            PrintToChat(client, "\x04[SYSTEM]\x01 ► Steps required: 3");
            PrintToChat(client, "\x04[SYSTEM]\x01 ► Failure risk: 20%%");
        }
        case 2: {
            PrintToChat(client, "\x04[SYSTEM]\x01 ► Enhanced security active");
            PrintToChat(client, "\x04[SYSTEM]\x01 ► Steps required: 5");
            PrintToChat(client, "\x04[SYSTEM]\x01 ► Failure risk: 35%%");
        }
        case 3: {
            PrintToChat(client, "\x04[SYSTEM]\x01 ► Maximum security engaged");
            PrintToChat(client, "\x04[SYSTEM]\x01 ► Steps required: 7");
            PrintToChat(client, "\x04[SYSTEM]\x01 ► Failure risk: 50%%");
        }
    }
    
    PrintToChat(client, "\x04[SYSTEM]\x01 Type \x05!decrypt\x01 when prompted to continue hack...");
    CreateTimer(5.0, Timer_HackPrompt, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Command_Decrypt(int client, int args) {
    if (!g_bPlayerHacking[client]) {
        PrintToChat(client, "\x04[SYSTEM]\x01 No hack in progress... Type !hack to begin");
        return Plugin_Handled;
    }
    
    float currentTime = GetGameTime();
    if (currentTime < g_fNextHackTime[client]) {
        PrintToChat(client, "\x04[SYSTEM]\x01 System processing... Please wait...");
        return Plugin_Handled;
    }
    
    g_iHackProgress[client]++;
    g_fNextHackTime[client] = currentTime + 5.0;
    
    // Failure chance based on difficulty
    int failChance = (g_iHackDifficulty[client] == 1) ? 20 : (g_iHackDifficulty[client] == 2) ? 35 : 50;
    if (GetRandomInt(1, 100) <= failChance) {
        FailHack(client);
        return Plugin_Handled;
    }
    
    CreateTimer(5.0, Timer_HackPrompt, client, TIMER_FLAG_NO_MAPCHANGE);
    return Plugin_Handled;
}

void CompleteHack(int client) {
    g_bPlayerHacking[client] = false;
    g_iHackSuccesses[client]++;
    
    // Add success effects here
    ShowHackSuccess(client);
    
    // Cooldown based on difficulty
    float cooldown = (g_iHackDifficulty[client] == 1) ? 300.0 : (g_iHackDifficulty[client] == 2) ? 600.0 : 900.0;
    g_fNextHackAttempt[client] = GetGameTime() + cooldown;
    
    PrintToChat(client, "\x04[SYSTEM]\x01 HACK SUCCESSFUL! (Total Successes: %d)", g_iHackSuccesses[client]);
    PrintToChat(client, "\x04[SYSTEM]\x01 ACCESSING VALVE INTERNAL NETWORK...");
    
    // Get random classified info for current difficulty
    ArrayList tempArray = new ArrayList(MAX_MESSAGE_LENGTH);
    char info[MAX_MESSAGE_LENGTH];
    char level[2];
    
    // Filter messages for current difficulty
    for (int i = 0; i < g_ClassifiedInfo.Length; i++) {
        g_ClassifiedInfo.GetString(i, info, sizeof(info));
        SplitString(info, ";", level, sizeof(level));
        if (StringToInt(level) == g_iHackDifficulty[client]) {
            tempArray.PushString(info);
        }
    }
    
    // Get random message from filtered list
    if (tempArray.Length > 0) {
        int randomIndex = GetRandomInt(0, tempArray.Length - 1);
        tempArray.GetString(randomIndex, info, sizeof(info));
        
        // Remove difficulty level from message
        int pos = StrContains(info, ";");
        if (pos != -1) {
            strcopy(info, sizeof(info), info[pos + 1]);
        }
        
        switch(g_iHackDifficulty[client]) {
            case 1: PrintToChat(client, "\x04[PUBLIC SERVER]\x01 %s", info);
            case 2: PrintToChat(client, "\x04[DEVELOPMENT SERVER]\x01 %s", info);
            case 3: PrintToChat(client, "\x04[CONFIDENTIAL SERVER]\x01 %s", info);
        }
    }
    
    delete tempArray;
    
    // Different completion messages per difficulty
    switch(g_iHackDifficulty[client]) {
        case 1: {
            PrintToChat(client, "\x04[SYSTEM]\x01 Basic security bypassed. Try a higher difficulty!");
            PrintToChat(client, "\x04[WARNING]\x01 Public server access locked for %d minutes.", RoundToFloor(cooldown/60.0));
        }
        case 2: {
            PrintToChat(client, "\x04[SYSTEM]\x01 Development server breached. Impressive work.");
            PrintToChat(client, "\x04[WARNING]\x01 Enhanced security lockdown: %d minutes.", RoundToFloor(cooldown/60.0));
        }
        case 3: {
            PrintToChat(client, "\x04[SYSTEM]\x01 Maximum security penetrated! Top-level access achieved!");
            PrintToChat(client, "\x04[CRITICAL]\x01 System lockdown initiated: %d minutes.", RoundToFloor(cooldown/60.0));
        }
    }
}

void LoadClassifiedInfo() {
    delete g_ClassifiedInfo;
    g_ClassifiedInfo = new ArrayList(MAX_MESSAGE_LENGTH);
    
    // LEVEL 1 - Basic Security (Public Development Info)
    AddClassifiedInfo(1, "[L4D3_STATUS] Build_Version.exe: Development phase ACTIVE - Progress: 47%");
    AddClassifiedInfo(1, "[L4D3_ENGINE] Source2_Core.dll: Engine adaptation 82% complete");
    AddClassifiedInfo(1, "[L4D3_RENDER] Graphics_Update.cfg: Next-gen rendering system operational");
    AddClassifiedInfo(1, "[L4D3_INFECTED] NewStrains.dat: Additional mutation types in testing");
    AddClassifiedInfo(1, "[L4D3_BUILD] Internal_Test.exe: Playtest build 0.8.2 deployed");
    
    // LEVEL 2 - Enhanced Security (Specific Features)
    AddClassifiedInfo(2, "[L4D3_COOP] PlayerSystem.sys: 8-player framework successfully tested");
    AddClassifiedInfo(2, "[L4D3_AI] Director3_Core.dll: Advanced AI behavior patterns implemented");
    AddClassifiedInfo(2, "[L4D3_ENVIRONMENT] WeatherEngine.dat: Dynamic storm system integrated");
    AddClassifiedInfo(2, "[L4D3_GORE] ZombiePhysics.cfg: Enhanced dismemberment module active");
    AddClassifiedInfo(2, "[L4D3_NETWORK] ServerCore.sys: 128-tick architecture optimized");
    
    // LEVEL 3 - Maximum Security (Confidential Details)
    AddClassifiedInfo(3, "[VALVE_INTERNAL]\nPROJECT: L4D3_RELEASE_SCHEDULE\nBUILD: 2.0.4.5891a\nTARGET: Q3_2028\nSTATUS: CONFIRMED\nCLEARANCE: LEVEL_3_REQUIRED\n//END");
    AddClassifiedInfo(3, "[L4D3_ENTITIES] SpecialInfected_New.dat: Three variants ready for implementation");
    AddClassifiedInfo(3, "[L4D3_PREVIEW] MarketingBuild.exe: Steam showcase build compiled");
    AddClassifiedInfo(3, "[L4D3_TESTING] BetaPhase.sys: Closed testing protocols prepared");
    AddClassifiedInfo(3, "[L4D3_ENGINE] Source2_Update.cfg: Full engine features unlocked");
}

public Action Command_HackSystem(int client, int args) {
    // Check if hacking is enabled
    if (!g_hHackingEnabled.BoolValue) {
        PrintToChat(client, "\x04[SYSTEM]\x01 ERROR: Hacking module currently offline.");
        PrintToChat(client, "\x04[SYSTEM]\x01 Access denied: Security protocol active.");
        return Plugin_Handled;
    }

    float currentTime = GetGameTime();
    
    // Check cooldown
    if (currentTime < g_fNextHackAttempt[client]) {
        int timeLeft = RoundToFloor(g_fNextHackAttempt[client] - currentTime);
        PrintToChat(client, "\x04[SYSTEM]\x01 System locked. Try again in %d seconds.", timeLeft);
        return Plugin_Handled;
    }
    
    // Show difficulty selection menu
    DisplayHackDifficultyMenu(client);
    return Plugin_Handled;
}

void DisplayHackDifficultyMenu(int client) {
    Menu menu = new Menu(HackDifficultyMenuHandler);
    
    char title[512];
    char buffer[128];
    
    strcopy(title, sizeof(title), "+--------------------------------+\n");
    StrCat(title, sizeof(title), "|     L4D3 INTRUSION SUITE      |\n");
    StrCat(title, sizeof(title), "+--------------------------------+\n");
    
    Format(buffer, sizeof(buffer), "| ACCESS ID: %d-%d    |\n", GetRandomInt(1000, 9999), GetRandomInt(100, 999));
    StrCat(title, sizeof(title), buffer);
    
    Format(buffer, sizeof(buffer), "| SUCCESSES: %d  FAILS: %d      |\n", g_iHackSuccesses[client], g_iHackFails[client]);
    StrCat(title, sizeof(title), buffer);
    
    StrCat(title, sizeof(title), "+--------------------------------+\n");
    StrCat(title, sizeof(title), "|    SELECT INTRUSION LEVEL     |\n");
    StrCat(title, sizeof(title), "+--------------------------------+");
    
    menu.SetTitle(title);
    
    menu.AddItem("1", ">> LEVEL 1 - BASIC SECURITY\n   > Easy breach, low risk");
    menu.AddItem("2", ">> LEVEL 2 - ENHANCED PROTECTION\n   > Medium security, moderate risk");
    menu.AddItem("3", ">> LEVEL 3 - MAXIMUM SECURITY\n   > High security, critical risk");
    
    menu.ExitButton = true;
    menu.Display(client, 20);
}

public int HackDifficultyMenuHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));
        g_iHackDifficulty[client] = StringToInt(info);
        StartHacking(client);
    }
    return 0;
}

public Action Timer_HackPrompt(Handle timer, any client) {
    if (!g_bPlayerHacking[client]) return Plugin_Stop;
    
    int maxSteps = (g_iHackDifficulty[client] == 1) ? 3 : (g_iHackDifficulty[client] == 2) ? 5 : 7;
    
    if (g_iHackProgress[client] >= maxSteps) {
        CompleteHack(client);
        return Plugin_Stop;
    }
    
    // Different prompts based on progress
    switch(g_iHackProgress[client]) {
        case 0: PrintToChat(client, "\x04[SYSTEM]\x01 FIREWALL DETECTED - Type !decrypt to bypass...");
        case 1: PrintToChat(client, "\x04[SYSTEM]\x01 ACCESSING SERVERS - Type !decrypt to continue...");
        case 2: PrintToChat(client, "\x04[SYSTEM]\x01 DOWNLOADING DATA - Type !decrypt to extract...");
        case 3: PrintToChat(client, "\x04[SYSTEM]\x01 BYPASSING SECURITY - Type !decrypt to proceed...");
        case 4: PrintToChat(client, "\x04[SYSTEM]\x01 CRACKING ENCRYPTION - Type !decrypt to decode...");
        case 5: PrintToChat(client, "\x04[SYSTEM]\x01 DEEP SCAN REQUIRED - Type !decrypt to analyze...");
        case 6: PrintToChat(client, "\x04[SYSTEM]\x01 FINAL BARRIER - Type !decrypt for extraction...");
    }
    
    return Plugin_Continue;
}

void AddClassifiedInfo(int level, const char[] info) {
    char leveledInfo[MAX_MESSAGE_LENGTH];
    Format(leveledInfo, sizeof(leveledInfo), "%d;%s", level, info);
    g_ClassifiedInfo.PushString(leveledInfo);
}

public void ConVarChanged_HackingEnabled(ConVar convar, const char[] oldValue, const char[] newValue) {
    if (!g_hHackingEnabled.BoolValue) {
        // Cancel all active hacking attempts
        for (int i = 1; i <= MaxClients; i++) {
            if (g_bPlayerHacking[i]) {
                PrintToChat(i, "\x04[SYSTEM]\x01 WARNING: Security override activated!");
                PrintToChat(i, "\x04[SYSTEM]\x01 Hacking attempt terminated.");
                g_bPlayerHacking[i] = false;
            }
        }
        PrintToServer("[L4D3 Leaks] Hacking module disabled");
    } else {
        PrintToServer("[L4D3 Leaks] Hacking module enabled");
    }
}

public void ConVarChanged_LeakMessages(ConVar convar, const char[] oldValue, const char[] newValue) {
    if (!g_hLeakMessagesEnabled.BoolValue) {
        // Stop the timer if messages are disabled
        if (g_hTimer != null) {
            delete g_hTimer;
            g_hTimer = null;
        }
        PrintToServer("[L4D3 Leaks] Leak messages disabled");
    } else {
        // Start timer if messages are enabled
        if (g_hTimer == null) {
            CreateMessageTimer();
        }
        PrintToServer("[L4D3 Leaks] Leak messages enabled");
    }
}

public Action Timer_CheckMessages(Handle timer) {
    if (!g_hLeakMessagesEnabled.BoolValue) {
        return Plugin_Continue;
    }

    static float nextMessageTime = 0.0;
    float currentTime = GetGameTime();
    
    // Always send messages, regardless of player count
    if (currentTime >= nextMessageTime) {
        // Get random message
        int messageCount = g_Messages.Length;
        int randomIndex = GetRandomInt(0, messageCount - 1);
        
        char message[MAX_MESSAGE_LENGTH];
        g_Messages.GetString(randomIndex, message, sizeof(message));
        
        SendLeakMessage(message);
        
        // Set next message time
        nextMessageTime = currentTime + GetRandomFloat(g_hMinDelay.FloatValue, g_hMaxDelay.FloatValue);
        PrintToServer("[L4D3 Leaks] Next message in: %.1f seconds", nextMessageTime - currentTime);
    }
    
    return Plugin_Continue;
}

void CreateHelpTimer() {
    delete g_hHelpTimer;
    g_hHelpTimer = CreateTimer(GetRandomFloat(60.0, 120.0), Timer_HelpMessage, _, TIMER_REPEAT);
}

public Action Timer_HelpMessage(Handle timer) {
    if (!g_hHackingEnabled.BoolValue) {
        return Plugin_Continue;
    }
    
    // Randomly select one of several hacker-themed messages
    switch(GetRandomInt(1, 4)) {
        case 1: {
            PrintToChatAll("\x04[SYSTEM]\x01 L4D3 development server detected - Type \x05!hack\x01 to access classified files!");
        }
        case 2: {
            PrintToChatAll("\x04[SYSTEM]\x01 L4D3 internal build database located - Use \x05!hack\x01 to breach security!");
        }
        case 3: {
            PrintToChatAll("\x04[SYSTEM]\x01 L4D3 test server firewall active - Type \x05!hack\x01 to decrypt files!");
        }
        case 4: {
            PrintToChatAll("\x04[SYSTEM]\x01 L4D3 confidential data detected - Initialize \x05!hack\x01 to access!");
        }
    }
    
    // Set next random interval
    CreateHelpTimer();
    
    return Plugin_Continue;
}

void ShowHackSuccess(int client) {
    // Green screen flash
    UTIL_ScreenFade(client, 0, 255, 0, 50, 0.1, 0.5);  // Green tint
    
    // Screen shake on success (mild)
    UTIL_ScreenShake(client, 5.0, 1.0, 0.5);
    
    // Success overlay message
    Handle hBuffer = StartMessageOne("Fade", client);
    if(hBuffer != null) {
        BfWriteShort(hBuffer, 1000);  // Fade duration
        BfWriteShort(hBuffer, 500);   // Hold time
        BfWriteShort(hBuffer, 0x0001);// Fade in flag
        BfWriteByte(hBuffer, 0);      // Red
        BfWriteByte(hBuffer, 255);    // Green
        BfWriteByte(hBuffer, 0);      // Blue
        BfWriteByte(hBuffer, 50);     // Alpha
        EndMessage();
    }
    
    // Success sound - Medal sound
    EmitSoundToClient(client, "ui/survival_medal.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
    
    // Center screen message
    PrintCenterText(client, "╔══ ACCESS GRANTED ══╗\n► L4D3 Data Retrieved ◄\n╚═══════════════════╝");
    
    // Chat messages
    PrintToChat(client, "\x04[SYSTEM]\x01 ╔════════════════════════════");
    PrintToChat(client, "\x04[SYSTEM]\x01 ║ ACCESS GRANTED - Level %d", g_iHackDifficulty[client]);
    PrintToChat(client, "\x04[SYSTEM]\x01 ║ L4D3 Data Successfully Retrieved");
    PrintToChat(client, "\x04[SYSTEM]\x01 ║ Total Successes: %d", g_iHackSuccesses[client]);
    PrintToChat(client, "\x04[SYSTEM]\x01 ╚════════════════════════════");
}

void ShowHackFailure(int client) {
    // Red screen flash
    UTIL_ScreenFade(client, 255, 0, 0, 75, 0.2, 0.5);  // Red tint
    
    // Screen shake on failure (intense)
    UTIL_ScreenShake(client, 15.0, 2.0, 1.0);
    
    // Failure overlay message
    Handle hBuffer = StartMessageOne("Fade", client);
    if(hBuffer != null) {
        BfWriteShort(hBuffer, 1000);  // Fade duration
        BfWriteShort(hBuffer, 500);   // Hold time
        BfWriteShort(hBuffer, 0x0001);// Fade in flag
        BfWriteByte(hBuffer, 255);    // Red
        BfWriteByte(hBuffer, 0);      // Green
        BfWriteByte(hBuffer, 0);      // Blue
        BfWriteByte(hBuffer, 75);     // Alpha
        EndMessage();
    }
    
    // Failure sound
    EmitSoundToClient(client, "buttons/button10.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
    
    // Center screen message
    PrintCenterText(client, "╔═══ ACCESS DENIED ═══╗\n► Security Breach Failed ◄\n╚════════════════════╝");
    
    // Chat messages
    PrintToChat(client, "\x04[SYSTEM]\x01 ╔════════════════════════════");
    PrintToChat(client, "\x04[SYSTEM]\x01 ║ ACCESS DENIED - Level %d", g_iHackDifficulty[client]);
    PrintToChat(client, "\x04[SYSTEM]\x01 ║ Security System Detected Intrusion");
    PrintToChat(client, "\x04[SYSTEM]\x01 ║ Total Failures: %d", g_iHackFails[client]);
    PrintToChat(client, "\x04[SYSTEM]\x01 ╚════════════════════════════");
}

void UTIL_ScreenFade(int client, int r, int g, int b, int alpha, float fadeTime, float holdTime) {
    Handle hFadeClient = StartMessageOne("Fade", client);
    if(hFadeClient != null) {
        BfWriteShort(hFadeClient, RoundFloat(fadeTime * 1000));  // Fade duration
        BfWriteShort(hFadeClient, RoundFloat(holdTime * 1000));  // Hold time
        BfWriteShort(hFadeClient, 0x0001);  // Fade in flag
        BfWriteByte(hFadeClient, r);        // Red
        BfWriteByte(hFadeClient, g);        // Green
        BfWriteByte(hFadeClient, b);        // Blue
        BfWriteByte(hFadeClient, alpha);    // Alpha
        EndMessage();
    }
}

void UTIL_ScreenShake(int client, float intensity, float duration, float frequency) {
    Handle hShake = StartMessageOne("Shake", client);
    if(hShake != null) {
        BfWriteByte(hShake, 0);                // Shake command
        BfWriteFloat(hShake, intensity);       // Shake magnitude
        BfWriteFloat(hShake, duration);        // Shake duration
        BfWriteFloat(hShake, frequency);       // Shake frequency
        EndMessage();
    }
}

void FailHack(int client) {
    g_bPlayerHacking[client] = false;
    g_iHackFails[client]++;
    
    // Add failure effects here
    ShowHackFailure(client);
    
    // Add cooldown based on number of failures
    float failCooldown = 60.0 * g_iHackFails[client]; // 1 minute per fail
    g_fNextHackAttempt[client] = GetGameTime() + failCooldown;
    
    PrintToChat(client, "\x04[SYSTEM]\x01 WARNING: Intrusion detected!");
    PrintToChat(client, "\x04[SYSTEM]\x01 Connection terminated... Try again in %d minutes.", RoundToFloor(failCooldown/60.0));
    PrintToChat(client, "\x04[SYSTEM]\x01 Total failed attempts: %d", g_iHackFails[client]);
}

void ShowL4D3Survey(int client) {
    Menu menu = new Menu(MainSurveyMenuHandler);
    
    menu.SetTitle("╔═══ L4D3 RESEARCH ═══╗\n╚════════════════════╝");
    
    menu.AddItem("maps", "► MAP FEATURES\n- New locations\n- Dynamic events\n- Weather system");
    menu.AddItem("survivors", "► SURVIVOR FEATURES\n- New characters\n- Class abilities\n- Customization");
    menu.AddItem("infected", "► INFECTED FEATURES\n- New special infected\n- Boss mutations\n- AI improvements");
    menu.AddItem("weapons", "► WEAPON FEATURES\n- New weapons\n- Modification system\n- Melee combat");
    menu.AddItem("modes", "► GAME MODES\n- Campaign features\n- Versus updates\n- New modes");
    menu.AddItem("gameplay", "► GAMEPLAY FEATURES\n- Core mechanics\n- Physics system\n- Interaction options");
    
    // Force the menu to stay open
    menu.ExitButton = false;
    menu.ExitBackButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

void ShowGameplaySubmenu(int client) {
    Menu menu = new Menu(GameplaySubmenuHandler);
    menu.SetTitle("╔═══ GAMEPLAY FEATURES ═══╗\n╚════════════════════════╝");
    
    menu.AddItem("► STEALTH TAKEDOWNS\n- Silent elimination\n- Tactical advantage", 
                "► STEALTH TAKEDOWNS\n- Silent elimination\n- Tactical advantage");
    menu.AddItem("► PARKOUR SYSTEM\n- Advanced movement\n- Environmental navigation", 
                "► PARKOUR SYSTEM\n- Advanced movement\n- Environmental navigation");
    menu.AddItem("► PHYSICS ENGINE\n- Realistic impacts\n- Dynamic interactions", 
                "► PHYSICS ENGINE\n- Realistic impacts\n- Dynamic interactions");
    menu.AddItem("► CRAFTING SYSTEM\n- Resource combination\n- Custom equipment", 
                "► CRAFTING SYSTEM\n- Resource combination\n- Custom equipment");
    
    menu.ExitButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

void ShowWeatherSubmenu(int client) {
    Menu menu = new Menu(WeatherDetailHandler);
    menu.SetTitle("╔═══ WEATHER SYSTEM ═══╗\n╚═══════════════════╝");
    
    menu.AddItem("rain", "► HEAVY RAIN\n  - Reduces visibility\n  - Affects fire spread\n  - Slippery surfaces");
    
    menu.AddItem("storm", "► THUNDER & LIGHTNING\n  - Temporary light flashes\n  - Startles infected\n  - Creates fire hazards");
    
    menu.AddItem("fog", "► DYNAMIC FOG\n  - Variable density\n  - Conceals special infected\n  - Affects gameplay strategy");
    
    menu.AddItem("snow", "► SNOW STORMS\n  - Slows movement speed\n  - Leaves footprints\n  - Reduces temperature");
    
    menu.AddItem("wind", "► STRONG WINDS\n  - Affects projectiles\n  - Moves objects\n  - Creates new paths");
    
    menu.AddItem("flood", "► FLASH FLOODS\n  - Changes map layout\n  - Creates water hazards\n  - Forces high ground");
    
    menu.ExitButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

void ShowPhysicsSubmenu(int client) {
    Menu menu = new Menu(PhysicsDetailHandler);
    menu.SetTitle("╔═══ PHYSICS & GORE ═══╗\n╚═══════════════════╝");
    
    menu.AddItem("dismember", "► ADVANCED DISMEMBERMENT\n  - Realistic body damage\n  - Affects zombie behavior\n  - Visual feedback");
    
    menu.AddItem("ragdoll", "► ENHANCED RAGDOLLS\n  - Dynamic body physics\n  - Environmental interaction\n  - Impact reactions");
    
    menu.AddItem("destruction", "► ENVIRONMENT DESTRUCTION\n  - Breakable walls\n  - Collapsing structures\n  - Dynamic cover");
    
    menu.AddItem("particles", "► BLOOD & GORE\n  - Persistent blood trails\n  - Enhanced visual effects\n  - Performance optimized");
    
    menu.AddItem("impact", "► WEAPON IMPACTS\n  - Weapon-specific effects\n  - Material-based reactions\n  - Realistic feedback");
    
    menu.AddItem("explosion", "► EXPLOSION PHYSICS\n  - Shockwave effects\n  - Object scattering\n  - Chain reactions");
    
    menu.ExitButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

void ShowBossInfectedSubmenu(int client) {
    Menu menu = new Menu(BossInfectedDetailHandler);
    menu.SetTitle("╔═══ BOSS INFECTED ═══╗\n╚══════════════════╝");
    
    menu.AddItem("mega_tank", "► MEGA TANK\n  - Double size tank\n  - Multiple rock throws\n  - Devastating charge");
    
    menu.AddItem("hive_mind", "► HIVE MIND\n  - Controls lesser infected\n  - Strategic spawning\n  - Area domination");
    
    menu.AddItem("behemoth", "► THE BEHEMOTH\n  - Building sized\n  - Map-changing attacks\n  - Multi-stage fight");
    
    menu.AddItem("infector", "► THE INFECTOR\n  - Creates mutations\n  - Spreads plague\n  - Evolves zombies");
    
    menu.AddItem("titan", "► THE TITAN\n  - Armored boss\n  - Weak points system\n  - Team coordination");
    
    menu.AddItem("queen", "► INFECTED QUEEN\n  - Spawns special infected\n  - Healing aura\n  - Ultimate abilities");
    
    menu.ExitButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int MainSurveyMenuHandler(Menu menu, MenuAction action, int client, int param2) {
    switch (action) {
        case MenuAction_Select: {
            char info[32];
            menu.GetItem(param2, info, sizeof(info));
            
            // Show appropriate submenu based on selection
            if (StrEqual(info, "maps")) ShowMapSubmenu(client);
            else if (StrEqual(info, "survivors")) ShowSurvivorSubmenu(client);
            else if (StrEqual(info, "infected")) ShowInfectedSubmenu(client);
            else if (StrEqual(info, "weapons")) ShowWeaponSubmenu(client);
            else if (StrEqual(info, "modes")) ShowModesSubmenu(client);
            else if (StrEqual(info, "gameplay")) ShowGameplaySubmenu(client);
        }
        
        case MenuAction_Cancel: {
            // Only show menu again if they haven't voted and it was explicitly closed
            if (!g_HasVoted[client] && param2 == MenuCancel_Exit) {
                // Use a timer to prevent immediate recursion
                CreateTimer(0.1, Timer_ReshowMenu, GetClientUserId(client));
            }
        }
        
        case MenuAction_End: {
            delete menu;
        }
    }
    return 0;
}

public Action Timer_ReshowMenu(Handle timer, any userid) {
    int client = GetClientOfUserId(userid);
    if (client > 0 && IsClientInGame(client) && !g_HasVoted[client]) {
        ShowL4D3Survey(client);
    }
    return Plugin_Stop;
}

public int GameplaySubmenuHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        char info[256];
        menu.GetItem(param2, info, sizeof(info));
        ProcessVote(client, "GAMEPLAY", info);
    }
    else if (action == MenuAction_Cancel && !g_HasVoted[client]) {
        ShowL4D3Survey(client);
    }
    return 0;
}

public int WeatherDetailHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        char info[256];
        menu.GetItem(param2, info, sizeof(info));
        ProcessVote(client, "WEATHER", info);
    }
    else if (action == MenuAction_Cancel && !g_HasVoted[client]) {
        ShowWeatherSubmenu(client);
    }
    return 0;
}

public int PhysicsDetailHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        char info[256];
        menu.GetItem(param2, info, sizeof(info));
        ProcessVote(client, "PHYSICS", info);
    }
    else if (action == MenuAction_Cancel && !g_HasVoted[client]) {
        ShowPhysicsSubmenu(client);
    }
    return 0;
}

public int InfectedSubmenuHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        char info[256];
        menu.GetItem(param2, info, sizeof(info));
        ProcessVote(client, "INFECTED", info);  // Direct vote processing instead of showing detail submenu
    }
    else if (action == MenuAction_Cancel && !g_HasVoted[client]) {
        ShowL4D3Survey(client);
    }
    return 0;
}

public int SpecialInfectedDetailHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        char info[256];
        menu.GetItem(param2, info, sizeof(info));
        ProcessVote(client, "SPECIAL_INFECTED", info);
    }
    else if (action == MenuAction_Cancel && !g_HasVoted[client]) {
        ShowL4D3Survey(client);
    }
    return 0;
}

public int SurvivorSubmenuHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        char info[256];
        menu.GetItem(param2, info, sizeof(info));
        ShowSurvivorDetailSubmenu(client, info);  // Show detail submenu instead of direct vote
    }
    else if (action == MenuAction_Cancel && !g_HasVoted[client]) {
        ShowL4D3Survey(client);
    }
    return 0;
}

public int WeaponSubmenuHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        char info[256];
        menu.GetItem(param2, info, sizeof(info));
        ShowWeaponDetailSubmenu(client, info);  // Show detail submenu instead of direct vote
    }
    else if (action == MenuAction_Cancel && !g_HasVoted[client]) {
        ShowL4D3Survey(client);
    }
    return 0;
}

public int MapSubmenuHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        char info[256];
        menu.GetItem(param2, info, sizeof(info));
        ShowMapDetailSubmenu(client, info);  // Show detail submenu instead of direct vote
    }
    else if (action == MenuAction_Cancel && !g_HasVoted[client]) {
        ShowL4D3Survey(client);
    }
    return 0;
}

public int ModesSubmenuHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        char info[256];
        menu.GetItem(param2, info, sizeof(info));
        ShowModesDetailSubmenu(client, info);  // Show the detail submenu instead of direct vote
    }
    else if (action == MenuAction_Cancel && !g_HasVoted[client]) {
        ShowL4D3Survey(client);
    }
    return 0;
}

void ShowSurvivorSubmenu(int client) {
    Menu menu = new Menu(SurvivorSubmenuHandler);
    menu.SetTitle("╔═══ SURVIVOR FEATURES ═══╗\n╚════════════════════════╝");
    
    menu.AddItem("► FIELD MEDIC\n- Advanced healing\n- Team support\n- Resource creation", 
                "► FIELD MEDIC\n- Advanced healing\n- Team support\n- Resource creation");
    menu.AddItem("► ASSAULT\n- Combat specialist\n- Weapon mastery\n- Front line focus", 
                "► ASSAULT\n- Combat specialist\n- Weapon mastery\n- Front line focus");
    menu.AddItem("► ENGINEER\n- Equipment expert\n- Area defense\n- Resource optimization", 
                "► ENGINEER\n- Equipment expert\n- Area defense\n- Resource optimization");
    menu.AddItem("► SCOUT\n- Fast movement\n- Resource finding\n- Early warning", 
                "► SCOUT\n- Fast movement\n- Resource finding\n- Early warning");
    
    menu.ExitButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

void ShowWeaponSubmenu(int client) {
    Menu menu = new Menu(WeaponSubmenuHandler);
    menu.SetTitle("╔═══ WEAPON FEATURES ═══╗\n╚═══════════════════════╝");
    
    menu.AddItem("► WEAPON MODS\n- Customization options\n- Performance upgrades", 
                "► WEAPON MODS\n- Customization options\n- Performance upgrades");
    menu.AddItem("► MELEE COMBAT\n- Advanced techniques\n- Close combat focus", 
                "► MELEE COMBAT\n- Advanced techniques\n- Close combat focus");
    menu.AddItem("► SPECIAL AMMO\n- Unique effects\n- Tactical options", 
                "► SPECIAL AMMO\n- Unique effects\n- Tactical options");
    menu.AddItem("► THROWABLES\n- New equipment\n- Strategic tools", 
                "► THROWABLES\n- New equipment\n- Strategic tools");
    
    menu.ExitButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

void ShowMapSubmenu(int client) {
    Menu menu = new Menu(MapSubmenuHandler);
    menu.SetTitle("╔═══ MAP FEATURES ═══╗\n╚═══════════════════╝");
    
    menu.AddItem("► DYNAMIC MAPS\n- Random generation\n- Environmental changes", 
                "► DYNAMIC MAPS\n- Random generation\n- Environmental changes");
    menu.AddItem("► MAP LOCATIONS\n- Diverse settings\n- Unique environments", 
                "► MAP LOCATIONS\n- Diverse settings\n- Unique environments");
    menu.AddItem("► SECRET AREAS\n- Hidden paths\n- Bonus content", 
                "► SECRET AREAS\n- Hidden paths\n- Bonus content");
    menu.AddItem("► MAP EVENTS\n- Random encounters\n- Special objectives", 
                "► MAP EVENTS\n- Random encounters\n- Special objectives");
    menu.AddItem("► WEATHER IMPACT\n- Environmental effects\n- Strategic changes", 
                "► WEATHER IMPACT\n- Environmental effects\n- Strategic changes");
    
    menu.ExitButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

void ShowModesSubmenu(int client) {
    Menu menu = new Menu(ModesSubmenuHandler);
    menu.SetTitle("╔═══ GAME MODES ═══╗\n╚══════════════════╝");
    
    menu.AddItem("► STORY MODE\n- Campaign structure\n- Character development", 
                "► STORY MODE\n- Campaign structure\n- Character development");
    menu.AddItem("► VERSUS MODE\n- Competitive play\n- Team balance", 
                "► VERSUS MODE\n- Competitive play\n- Team balance");
    menu.AddItem("► SURVIVAL MODE\n- Wave defense\n- Resource management", 
                "► SURVIVAL MODE\n- Wave defense\n- Resource management");
    menu.AddItem("► CHALLENGE MODE\n- Special rulesets\n- Unique rewards", 
                "► CHALLENGE MODE\n- Special rulesets\n- Unique rewards");
    
    menu.ExitButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

public void OnClientPutInServer(int client) {
    if (!IsFakeClient(client) && !g_HasVoted[client] && !g_bFirstJoin[client]) {
        g_bFirstJoin[client] = true;
        // 10 second delay
        CreateTimer(10.0, Timer_ShowSurvey, GetClientUserId(client));
    }
}

public Action Timer_ShowSurvey(Handle timer, any userid) {
    int client = GetClientOfUserId(userid);
    
    if (client > 0 && IsClientInGame(client) && !IsFakeClient(client) && !g_HasVoted[client]) {
        // Atmospheric chat message first
        PrintToChat(client, "\x04[VALVE]\x01 ╔════════════════════════════");
        PrintToChat(client, "\x04[VALVE]\x01 ║ L4D3 Development Survey");
        PrintToChat(client, "\x04[VALVE]\x01 ║ Your input will shape the future");
        PrintToChat(client, "\x04[VALVE]\x01 ╚════════════════════════════");
        
        // Show menu immediately after chat message
        ShowL4D3Survey(client);
    }
    return Plugin_Stop;
}

void ShowWeatherDetailSubmenu(int client, const char[] feature) {
    Menu menu = new Menu(WeatherFinalDetailHandler);
    
    if (StrEqual(feature, "rain")) {
        menu.SetTitle("╔═══ RAIN SYSTEM DETAILS ═══╗\n╚════════════════════════╝");
        menu.AddItem("rain_1", "► RAIN INTENSITY\n- Light drizzle to storm\n- Affects visibility range\n- Dynamic puddle formation");
        menu.AddItem("rain_2", "► ENVIRONMENTAL EFFECTS\n- Slippery surfaces\n- Reduced fire spread\n- Water level rising");
        menu.AddItem("rain_3", "► GAMEPLAY IMPACT\n- Sound masking\n- Infected behavior changes\n- Resource protection needed");
        menu.AddItem("rain_4", "► VISUAL EFFECTS\n- Realistic water drops\n- Screen effects\n- Lightning integration");
        menu.AddItem("rain_5", "► STRATEGIC ELEMENTS\n- Safe house flooding\n- Alternative routes\n- Weather shelter mechanics");
    }
    else if (StrEqual(feature, "storm")) {
        menu.SetTitle("╔═══ STORM SYSTEM DETAILS ═══╗\n╚═════════════════════════╝");
        menu.AddItem("storm_1", "► LIGHTNING MECHANICS\n- Random strikes\n- Temporary illumination\n- Fire hazard creation");
        menu.AddItem("storm_2", "► THUNDER EFFECTS\n- Sound masking\n- Infected startling\n- Distance calculation");
        menu.AddItem("storm_3", "► WIND IMPACT\n- Object movement\n- Projectile deviation\n- Movement penalties");
        menu.AddItem("storm_4", "► DEBRIS SYSTEM\n- Flying objects\n- Damage potential\n- Cover destruction");
        menu.AddItem("storm_5", "► SURVIVAL ASPECTS\n- Indoor advantages\n- Resource scarcity\n- Emergency planning");
    }
    else if (StrEqual(feature, "fog")) {
        menu.SetTitle("╔═══ FOG SYSTEM DETAILS ═══╗\n╚════════════════════════╝");
        menu.AddItem("fog_1", "► DENSITY CONTROL\n- Variable thickness\n- Distance scaling\n- Time-based changes");
        menu.AddItem("fog_2", "► VISIBILITY IMPACT\n- Range reduction\n- Object obscuring\n- Navigation challenges");
        menu.AddItem("fog_3", "► TACTICAL ELEMENTS\n- Stealth advantages\n- Infected concealment\n- Team coordination");
        menu.AddItem("fog_4", "► ATMOSPHERE\n- Color variations\n- Particle effects\n- Mood enhancement");
        menu.AddItem("fog_5", "► GAMEPLAY EFFECTS\n- Special infected bonus\n- Survivor penalties\n- Strategic planning");
    }
    else if (StrEqual(feature, "day_night")) {
        menu.SetTitle("╔═══ DAY/NIGHT DETAILS ═══╗\n╚═════════════════════════╝");
        menu.AddItem("cycle_1", "► TIME SYSTEM\n- Dynamic cycle\n- Event triggers\n- Atmosphere changes");
        menu.AddItem("cycle_2", "► LIGHTING EFFECTS\n- Real-time shadows\n- Visibility changes\n- Mood setting");
        menu.AddItem("cycle_3", "► GAMEPLAY IMPACT\n- Night dangers\n- Day advantages\n- Strategic timing");
        menu.AddItem("cycle_4", "► INFECTED BEHAVIOR\n- Time-based aggression\n- Special abilities\n- Spawn patterns");
        menu.AddItem("cycle_5", "► SURVIVOR TOOLS\n- Light sources\n- Night vision\n- Tactical equipment");
    }
    else if (StrEqual(feature, "snow")) {
        menu.SetTitle("╔═══ SNOW SYSTEM DETAILS ═══╗\n╚═════════════════════════╝");
        menu.AddItem("snow_1", "► ACCUMULATION\n- Dynamic buildup\n- Path blocking\n- Depth variation");
        menu.AddItem("snow_2", "► MOVEMENT IMPACT\n- Speed reduction\n- Footprint tracking\n- Stamina drain");
        menu.AddItem("snow_3", "► VISIBILITY\n- Blizzard effects\n- Distance reduction\n- Disorientation");
        menu.AddItem("snow_4", "► SURVIVAL ASPECTS\n- Temperature system\n- Shelter importance\n- Resource management");
        menu.AddItem("snow_5", "► GAMEPLAY MECHANICS\n- Vehicle handling\n- Weapon effects\n- Strategic planning");
    }

    menu.ExitButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int WeatherFinalDetailHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));
        ProcessVote(client, "WEATHER_DETAIL", info);
    }
    else if (action == MenuAction_Cancel && !g_HasVoted[client]) {
        ShowWeatherSubmenu(client);
    }
    return 0;
}

void ShowGameplayDetailSubmenu(int client, const char[] feature) {
    Menu menu = new Menu(GameplayDetailHandler);
    menu.SetTitle("╔═══ GAMEPLAY DETAILS ═══╗\n╚════════════════════╝");
    
    if (StrEqual(feature, "► STEALTH TAKEDOWNS\n- Silent elimination\n- Tactical advantage")) {
        menu.AddItem("► STEALTH MECHANICS\n- Noise detection\n- Vision cones\n- Cover system", 
                    "► STEALTH MECHANICS\n- Noise detection\n- Vision cones\n- Cover system");
        menu.AddItem("► TAKEDOWN MOVES\n- Silent eliminations\n- Chain takedowns\n- Team executions", 
                    "► TAKEDOWN MOVES\n- Silent eliminations\n- Chain takedowns\n- Team executions");
        menu.AddItem("► STEALTH BENEFITS\n- Resource bonus\n- Special routes\n- Tactical advantages", 
                    "► STEALTH BENEFITS\n- Resource bonus\n- Special routes\n- Tactical advantages");
    }
    else if (StrEqual(feature, "► PARKOUR SYSTEM\n- Advanced movement\n- Environmental navigation")) {
        menu.AddItem("► MOVEMENT OPTIONS\n- Wall running\n- Slide tackles\n- Quick climbing", 
                    "► MOVEMENT OPTIONS\n- Wall running\n- Slide tackles\n- Quick climbing");
        menu.AddItem("► COMBAT MOBILITY\n- Combat rolls\n- Jump attacks\n- Tactical retreats", 
                    "► COMBAT MOBILITY\n- Combat rolls\n- Jump attacks\n- Tactical retreats");
        menu.AddItem("► ENVIRONMENT USE\n- Swing points\n- Zip lines\n- Interactive objects", 
                    "► ENVIRONMENT USE\n- Swing points\n- Zip lines\n- Interactive objects");
    }
    else if (StrEqual(feature, "► PHYSICS ENGINE\n- Realistic impacts\n- Dynamic interactions")) {
        menu.AddItem("► IMPACT SYSTEM\n- Weapon physics\n- Momentum effects\n- Ragdoll improvements", 
                    "► IMPACT SYSTEM\n- Weapon physics\n- Momentum effects\n- Ragdoll improvements");
        menu.AddItem("► ENVIRONMENT PHYSICS\n- Object destruction\n- Chain reactions\n- Dynamic cover", 
                    "► ENVIRONMENT PHYSICS\n- Object destruction\n- Chain reactions\n- Dynamic cover");
        menu.AddItem("► WEATHER PHYSICS\n- Wind effects\n- Water dynamics\n- Environmental hazards", 
                    "► WEATHER PHYSICS\n- Wind effects\n- Water dynamics\n- Environmental hazards");
    }
    
    menu.ExitButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int GameplayFinalDetailHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));
        
        if (StrEqual(info, "dynamic")) {
            ShowDynamicWeatherSubmenu(client);
        } else {
            ShowWeatherDetailSubmenu(client, info);
        }
    }
    else if (action == MenuAction_Cancel && !g_HasVoted[client]) {
        ShowGameplaySubmenu(client);
    }
    return 0;
}

void ShowSpecialInfectedDetailSubmenu(int client, const char[] feature) {
    Menu menu = new Menu(SpecialInfectedFinalHandler);
    
    if (StrEqual(feature, "climber")) {
        menu.SetTitle("╔═══ THE CLIMBER ═══╗\n╚══════════════════╝");
        menu.AddItem("climb_1", "► WALL SCALING\n- Any surface climbing\n- Ceiling traversal\n- Speed variations\n- Stealth movement");
        menu.AddItem("climb_2", "► POUNCE MECHANICS\n- Height bonus damage\n- Directional control\n- Recovery time\n- Counter mechanics");
        menu.AddItem("climb_3", "► WEB CREATION\n- Temporary paths\n- Team movement\n- Trap setting\n- Environmental use");
        menu.AddItem("climb_4", "► SPECIAL ABILITIES\n- Quick escape\n- Team coordination\n- Multiple targets\n- Combat advantages");
        menu.AddItem("climb_5", "► EVOLUTION PATH\n- Skill upgrades\n- New abilities\n- Adaptation system\n- Mutation options");
    }
    else if (StrEqual(feature, "screamer")) {
        menu.SetTitle("╔═══ THE SCREAMER ═══╗\n╚═══════════════════╝");
        menu.AddItem("scream_1", "► SONIC ATTACKS\n- Stun effects\n- Damage waves\n- Range control\n- Sound mechanics");
        menu.AddItem("scream_2", "► HORDE CALLING\n- Special infected\n- Coordinated attacks\n- Timing system\n- Strategic spawns");
        menu.AddItem("scream_3", "► DISORIENTATION\n- Vision effects\n- Balance disruption\n- Team confusion\n- Recovery time");
        menu.AddItem("scream_4", "► ECHO LOCATION\n- Survivor detection\n- Team communication\n- Through walls\n- Range indicator");
        menu.AddItem("scream_5", "► VULNERABILITY\n- Weakness phases\n- Team protection\n- Counter timing\n- Risk management");
    }
    // Continue for other special infected...

    menu.ExitButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

void ShowBossInfectedDetailSubmenu(int client, const char[] feature) {
    Menu menu = new Menu(BossInfectedFinalHandler);
    
    if (StrEqual(feature, "mega_tank")) {
        menu.SetTitle("╔═══ MEGA TANK ═══╗\n╚════════════════╝");
        menu.AddItem("mtank_1", "► SIZE & STRENGTH\n- Massive scale\n- Building damage\n- Area control\n- Intimidation factor");
        menu.AddItem("mtank_2", "► ATTACK PATTERNS\n- Multi-rock throws\n- Ground pounds\n- Charge combos\n- Special moves");
        menu.AddItem("mtank_3", "► ARMOR SYSTEM\n- Damage reduction\n- Weak points\n- Progressive damage\n- Team focus");
        menu.AddItem("mtank_4", "► RAGE MECHANICS\n- Power scaling\n- Health triggers\n- Ultimate abilities\n- Time limits");
        menu.AddItem("mtank_5", "► TEAM IMPACT\n- Resource drain\n- Area denial\n- Tactical retreat\n- Coordination need");
    }
    // Continue for other boss infected...

    menu.ExitButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

void ShowWeaponDetailSubmenu(int client, const char[] feature) {
    Menu menu = new Menu(WeaponDetailHandler);
    menu.SetTitle("╔═══ WEAPON DETAILS ═══╗\n╚═══════════════════╝");
    
    if (StrEqual(feature, "► WEAPON MODS\n- Customization options\n- Performance upgrades")) {
        menu.AddItem("► ATTACHMENTS\n- Scopes and sights\n- Extended magazines\n- Custom grips", 
                    "► ATTACHMENTS\n- Scopes and sights\n- Extended magazines\n- Custom grips");
        menu.AddItem("► UPGRADES\n- Damage boosters\n- Rate of fire mods\n- Recoil control", 
                    "► UPGRADES\n- Damage boosters\n- Rate of fire mods\n- Recoil control");
        menu.AddItem("► CUSTOMIZATION\n- Weapon skins\n- Special effects\n- Kill tracking", 
                    "► CUSTOMIZATION\n- Weapon skins\n- Special effects\n- Kill tracking");
    }
    else if (StrEqual(feature, "► MELEE COMBAT\n- Advanced techniques\n- Close combat focus")) {
        menu.AddItem("► MELEE WEAPONS\n- New weapon types\n- Custom modifications\n- Special attacks", 
                    "► MELEE WEAPONS\n- New weapon types\n- Custom modifications\n- Special attacks");
        menu.AddItem("► COMBAT MOVES\n- Combo attacks\n- Counter strikes\n- Finishing moves", 
                    "► COMBAT MOVES\n- Combo attacks\n- Counter strikes\n- Finishing moves");
    }
    else if (StrEqual(feature, "► SPECIAL AMMO\n- Unique effects\n- Tactical options")) {
        menu.AddItem("► CRYO ROUNDS\n- Freezing effects\n- Movement slow\n- Shatter damage", 
                    "► CRYO ROUNDS\n- Freezing effects\n- Movement slow\n- Shatter damage");
        menu.AddItem("► SHOCK AMMO\n- Chain lightning\n- Stun effects\n- Electronics disable", 
                    "► SHOCK AMMO\n- Chain lightning\n- Stun effects\n- Electronics disable");
        menu.AddItem("► TOXIC SHELLS\n- Area denial\n- DOT damage\n- Vision impair", 
                    "► TOXIC SHELLS\n- Area denial\n- DOT damage\n- Vision impair");
        menu.AddItem("► PULSE ROUNDS\n- Shield breaking\n- Armor piercing\n- EMP effect", 
                    "► PULSE ROUNDS\n- Shield breaking\n- Armor piercing\n- EMP effect");
        menu.AddItem("► MARKING SHOTS\n- Target highlight\n- Damage bonus\n- Team tracking", 
                    "► MARKING SHOTS\n- Target highlight\n- Damage bonus\n- Team tracking");
    }
    else if (StrEqual(feature, "► THROWABLES\n- New equipment\n- Strategic tools")) {
        menu.AddItem("► NEW GRENADES\n- Tactical options\n- Area control\n- Special effects", 
                    "► NEW GRENADES\n- Tactical options\n- Area control\n- Special effects");
        menu.AddItem("► UTILITY ITEMS\n- Support tools\n- Team assistance\n- Strategic use", 
                    "► UTILITY ITEMS\n- Support tools\n- Team assistance\n- Strategic use");
        menu.AddItem("► COMBAT TOOLS\n- Offensive options\n- Defense items\n- Tactical equipment", 
                    "► COMBAT TOOLS\n- Offensive options\n- Defense items\n- Tactical equipment");
    }
    
    menu.ExitButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

void ShowMapDetailSubmenu(int client, const char[] feature) {
    Menu menu = new Menu(MapDetailHandler);
    menu.SetTitle("╔═══ MAP DETAILS ═══╗\n╚══════════════════╝");
    
    if (StrEqual(feature, "► DYNAMIC MAPS\n- Random generation\n- Environmental changes")) {
        menu.AddItem("► PROCEDURAL LAYOUTS\n- Unique paths each game\n- Dynamic objectives\n- Adaptive difficulty", 
                    "► PROCEDURAL LAYOUTS\n- Unique paths each game\n- Dynamic objectives\n- Adaptive difficulty");
        menu.AddItem("► DESTRUCTIBLE ENVIRONMENTS\n- Breakable walls\n- Collapsing structures\n- New pathways", 
                    "► DESTRUCTIBLE ENVIRONMENTS\n- Breakable walls\n- Collapsing structures\n- New pathways");
        menu.AddItem("► DYNAMIC EVENTS\n- Random encounters\n- Weather changes\n- Time-based challenges", 
                    "► DYNAMIC EVENTS\n- Random encounters\n- Weather changes\n- Time-based challenges");
    }
    else if (StrEqual(feature, "► SECRET AREAS\n- Hidden paths\n- Bonus content")) {
        menu.AddItem("► HIDDEN ROOMS\n- Special loot\n- Unique encounters\n- Story elements", 
                    "► HIDDEN ROOMS\n- Special loot\n- Unique encounters\n- Story elements");
        menu.AddItem("► SECRET PASSAGES\n- Alternative routes\n- Escape paths\n- Tactical advantages", 
                    "► SECRET PASSAGES\n- Alternative routes\n- Escape paths\n- Tactical advantages");
        menu.AddItem("► BONUS CONTENT\n- Easter eggs\n- Special rewards\n- Hidden challenges", 
                    "► BONUS CONTENT\n- Easter eggs\n- Special rewards\n- Hidden challenges");
    }
    else if (StrEqual(feature, "► MAP EVENTS\n- Random encounters\n- Special objectives")) {
        menu.AddItem("► RANDOM ENCOUNTERS\n- Special infected waves\n- Survivor rescues\n- Mini-bosses", 
                    "► RANDOM ENCOUNTERS\n- Special infected waves\n- Survivor rescues\n- Mini-bosses");
        menu.AddItem("► SPECIAL OBJECTIVES\n- Time-limited goals\n- Optional challenges\n- Bonus rewards", 
                    "► SPECIAL OBJECTIVES\n- Time-limited goals\n- Optional challenges\n- Bonus rewards");
        menu.AddItem("► EVENT VARIATIONS\n- Weather impacts\n- Time of day effects\n- Environmental hazards", 
                    "► EVENT VARIATIONS\n- Weather impacts\n- Time of day effects\n- Environmental hazards");
    }
    else if (StrEqual(feature, "► MAP LOCATIONS\n- Diverse settings\n- Unique environments")) {
        menu.AddItem("► URBAN ENVIRONMENTS\n- Skyscrapers\n- Underground metro\n- Shopping districts", 
                    "► URBAN ENVIRONMENTS\n- Skyscrapers\n- Underground metro\n- Shopping districts");
        menu.AddItem("► RURAL AREAS\n- Dense forests\n- Small towns\n- Farmlands", 
                    "► RURAL AREAS\n- Dense forests\n- Small towns\n- Farmlands");
        menu.AddItem("► INDUSTRIAL ZONES\n- Factories\n- Power plants\n- Storage facilities", 
                    "► INDUSTRIAL ZONES\n- Factories\n- Power plants\n- Storage facilities");
    }
    else if (StrEqual(feature, "► WEATHER IMPACT\n- Environmental effects\n- Strategic changes")) {
        menu.AddItem("► WEATHER SYSTEMS\n- Dynamic changes\n- Visual effects\n- Gameplay impact", 
                    "► WEATHER SYSTEMS\n- Dynamic changes\n- Visual effects\n- Gameplay impact");
        menu.AddItem("► ENVIRONMENTAL EFFECTS\n- Surface conditions\n- Visibility changes\n- Sound masking", 
                    "► ENVIRONMENTAL EFFECTS\n- Surface conditions\n- Visibility changes\n- Sound masking");
        menu.AddItem("► STRATEGIC ELEMENTS\n- Tactical advantages\n- Resource management\n- Team coordination", 
                    "► STRATEGIC ELEMENTS\n- Tactical advantages\n- Resource management\n- Team coordination");
    }
    
    menu.ExitButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

void ShowSurvivorDetailSubmenu(int client, const char[] feature) {
    Menu menu = new Menu(SurvivorDetailHandler);
    menu.SetTitle("╔═══ SURVIVOR DETAILS ═══╗\n╚════════════════════╝");
    
    if (StrEqual(feature, "► FIELD MEDIC\n- Advanced healing\n- Team support\n- Resource creation")) {
        menu.AddItem("► HEALING ABILITIES\n- Quick revive\n- Group healing\n- Advanced first aid", 
                    "► HEALING ABILITIES\n- Quick revive\n- Group healing\n- Advanced first aid");
        menu.AddItem("► SUPPORT SKILLS\n- Temporary buffs\n- Team protection\n- Resource sharing", 
                    "► SUPPORT SKILLS\n- Temporary buffs\n- Team protection\n- Resource sharing");
        menu.AddItem("► MEDICAL CRAFTING\n- Create supplies\n- Upgrade medkits\n- Special medicines", 
                    "► MEDICAL CRAFTING\n- Create supplies\n- Upgrade medkits\n- Special medicines");
    }
    else if (StrEqual(feature, "► ASSAULT\n- Combat specialist\n- Weapon mastery\n- Front line focus")) {
        menu.AddItem("► COMBAT MASTERY\n- Increased damage\n- Better accuracy\n- Faster reloads", 
                    "► COMBAT MASTERY\n- Increased damage\n- Better accuracy\n- Faster reloads");
        menu.AddItem("► TACTICAL SKILLS\n- Special ammo\n- Combat maneuvers\n- Team tactics", 
                    "► TACTICAL SKILLS\n- Special ammo\n- Combat maneuvers\n- Team tactics");
    }
    else if (StrEqual(feature, "► ENGINEER\n- Equipment expert\n- Area defense\n- Resource optimization")) {
        menu.AddItem("► FORTIFICATION\n- Barricade building\n- Defense upgrades\n- Area security", 
                    "► FORTIFICATION\n- Barricade building\n- Defense upgrades\n- Area security");
        menu.AddItem("► EQUIPMENT MASTERY\n- Tool creation\n- Device upgrades\n- Resource efficiency", 
                    "► EQUIPMENT MASTERY\n- Tool creation\n- Device upgrades\n- Resource efficiency");
        menu.AddItem("► DEFENSE SYSTEMS\n- Automated turrets\n- Trap placement\n- Area control", 
                    "► DEFENSE SYSTEMS\n- Automated turrets\n- Trap placement\n- Area control");
    }
    else if (StrEqual(feature, "► SCOUT\n- Fast movement\n- Resource finding\n- Early warning")) {
        menu.AddItem("► MOBILITY\n- Speed boosts\n- Parkour skills\n- Quick escapes", 
                    "► MOBILITY\n- Speed boosts\n- Parkour skills\n- Quick escapes");
        menu.AddItem("► DETECTION\n- Resource spotting\n- Danger warnings\n- Path finding", 
                    "► DETECTION\n- Resource spotting\n- Danger warnings\n- Path finding");
        menu.AddItem("► RECONNAISSANCE\n- Area scanning\n- Enemy marking\n- Team coordination", 
                    "► RECONNAISSANCE\n- Area scanning\n- Enemy marking\n- Team coordination");
    }
    
    menu.ExitButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

void ShowGameModeDetailSubmenu(int client, const char[] feature) {
    Menu menu = new Menu(GameModeFinalHandler);
    
    if (StrEqual(feature, "story")) {
        menu.SetTitle("╔═══ STORY MODE ═══╗\n╚══════════════════╝");
        menu.AddItem("story_campaign", "► CAMPAIGN STRUCTURE\n- Multiple chapters\n- Branching paths\n- Choice impact");
        menu.AddItem("story_narrative", "► NARRATIVE EVENTS\n- Dynamic stories\n- Character interaction\n- Plot twists");
        menu.AddItem("story_missions", "► MISSION TYPES\n- Main objectives\n- Side missions\n- Secret goals");
        menu.AddItem("story_progress", "► PROGRESSION\n- Character growth\n- Equipment unlock\n- Story reveals");
    }
    else if (StrEqual(feature, "versus")) {
        menu.SetTitle("╔═══ VERSUS MODE ═══╗\n╚═══════════════════╝");
        menu.AddItem("versus_team", "► TEAM MECHANICS\n- Balance system\n- Role switching\n- Score tracking");
        menu.AddItem("versus_infected", "► INFECTED PLAY\n- Special abilities\n- Coordination tools\n- Upgrade system");
        menu.AddItem("versus_survivor", "► SURVIVOR PLAY\n- Defense tactics\n- Resource management\n- Team coordination");
        menu.AddItem("versus_competitive", "► COMPETITIVE\n- Ranking system\n- Matchmaking\n- Tournaments");
    }
    else if (StrEqual(feature, "survival")) {
        menu.SetTitle("╔═══ SURVIVAL MODE ═══╗\n╚════════════════════╝");
        menu.AddItem("survival_waves", "► WAVE SYSTEM\n- Progressive difficulty\n- Special events\n- Boss waves");
        menu.AddItem("survival_resources", "► RESOURCES\n- Limited supplies\n- Strategic use\n- Team sharing");
        menu.AddItem("survival_upgrades", "► UPGRADES\n- In-match improvements\n- Special abilities\n- Team bonuses");
        menu.AddItem("survival_objectives", "► OBJECTIVES\n- Dynamic goals\n- Bonus tasks\n- Score multipliers");
    }
    else if (StrEqual(feature, "challenge")) {
        menu.SetTitle("╔═══ CHALLENGE MODE ═══╗\n╚════════════════════╝");
        menu.AddItem("challenge_rules", "► SPECIAL RULES\n- Unique conditions\n- Modified gameplay\n- Custom challenges");
        menu.AddItem("challenge_rewards", "► REWARDS\n- Special unlocks\n- Unique items\n- Achievement system");
        menu.AddItem("challenge_weekly", "► WEEKLY EVENTS\n- Rotating challenges\n- Special modifiers\n- Limited time");
        menu.AddItem("challenge_custom", "► CUSTOM CHALLENGES\n- Rule creation\n- Difficulty settings\n- Share system");
    }
    else if (StrEqual(feature, "custom")) {
        menu.SetTitle("╔═══ CUSTOM MODES ═══╗\n╚═══════════════════╝");
        menu.AddItem("custom_create", "► MODE CREATION\n- Rule settings\n- Gameplay modification\n- Balance tools");
        menu.AddItem("custom_share", "► SHARING SYSTEM\n- Mode publishing\n- Rating system\n- Community features");
        menu.AddItem("custom_browse", "► MODE BROWSER\n- Search options\n- Categories\n- Popular modes");
        menu.AddItem("custom_favorites", "► FAVORITES\n- Save modes\n- Quick access\n- Personal collection");
    }

    menu.ExitButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int MapFinalHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));
        ProcessVote(client, "MAP", info);
        
        // Show individual result
        PrintToChat(client, "\x04[VALVE]\x01 Thank you for voting on: %s", info);
        PrintToChat(client, "\x04[VALVE]\x01 Your feedback has been recorded.");
    }
    else if (action == MenuAction_Cancel && !g_HasVoted[client]) {
        ShowMapSubmenu(client);
    }
    return 0;
}

public int SurvivorFinalHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));
        ProcessVote(client, "SURVIVOR", info);
    }
    else if (action == MenuAction_Cancel && !g_HasVoted[client]) {
        ShowSurvivorSubmenu(client);
    }
    return 0;
}

public int GameModeFinalHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));
        ProcessVote(client, "GAMEMODE", info);
    }
    else if (action == MenuAction_Cancel && !g_HasVoted[client]) {
        ShowModesSubmenu(client);
    }
    return 0;
}

public int SpecialInfectedFinalHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));
        ProcessVote(client, "SPECIAL_INFECTED_DETAIL", info);
    }
    else if (action == MenuAction_Cancel && !g_HasVoted[client]) {
        ShowL4D3Survey(client); // Return to main menu instead
    }
    return 0;
}

public int BossInfectedFinalHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));
        ProcessVote(client, "BOSS_INFECTED_DETAIL", info);
    }
    else if (action == MenuAction_Cancel && !g_HasVoted[client]) {
        ShowBossInfectedSubmenu(client);
    }
    return 0;
}

public int WeaponFinalHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));
        ProcessVote(client, "WEAPON", info);
        
        // Show individual result
        PrintToChat(client, "\x04[VALVE]\x01 Thank you for voting on: %s", info);
        PrintToChat(client, "\x04[VALVE]\x01 Your feedback has been recorded.");
    }
    else if (action == MenuAction_Cancel && !g_HasVoted[client]) {
        ShowWeaponSubmenu(client);
    }
    return 0;
}

public int SpecialInfectedSubmenuHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));
        ShowSpecialInfectedDetailSubmenu(client, info);  // Show third level menu
    }
    else if (action == MenuAction_Cancel && !g_HasVoted[client]) {
        ShowL4D3Survey(client); // Return to main menu instead
    }
    return 0;
}

public int BossInfectedSubmenuHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));
        ShowBossInfectedDetailSubmenu(client, info);  // Show third level menu
    }
    else if (action == MenuAction_Cancel && !g_HasVoted[client]) {
        ShowBossInfectedSubmenu(client);
    }
    return 0;
}

public int GameModeSubmenuHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));
        ShowGameModeDetailSubmenu(client, info);  // Show third level menu
    }
    else if (action == MenuAction_Cancel && !g_HasVoted[client]) {
        ShowModesSubmenu(client);
    }
    return 0;
}

public int WeatherSubmenuHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));
        
        if (StrEqual(info, "dynamic")) {
            ShowDynamicWeatherSubmenu(client);  // Show dynamic weather options
        } else {
            ShowWeatherDetailSubmenu(client, info);  // Show other weather details
        }
    }
    else if (action == MenuAction_Cancel && !g_HasVoted[client]) {
        ShowWeatherSubmenu(client);
    }
    return 0;
}

void ShowDynamicWeatherSubmenu(int client) {
    Menu menu = new Menu(DynamicWeatherFinalHandler);
    menu.SetTitle("╔═══ DYNAMIC WEATHER DETAILS ═══╗\n╚════════════════════════════╝");
    
    menu.AddItem("dyn_weather_1", "► WEATHER TRANSITIONS\n- Smooth changes\n- Time-based events\n- Random occurrences");
    menu.AddItem("dyn_weather_2", "► ENVIRONMENT RESPONSE\n- Flora reactions\n- Water systems\n- Ground effects");
    menu.AddItem("dyn_weather_3", "► SEASONAL CHANGES\n- Temperature impact\n- Resource availability\n- Survival challenges");
    menu.AddItem("dyn_weather_4", "► WEATHER EVENTS\n- Special storms\n- Natural disasters\n- Emergency situations");
    menu.AddItem("dyn_weather_5", "► GAMEPLAY ADAPTATION\n- Strategy changes\n- Equipment needs\n- Team coordination");
    
    menu.ExitButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int DynamicWeatherDetailHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));
        ProcessVote(client, "DYNAMIC_WEATHER", info);
    }
    else if (action == MenuAction_Cancel && !g_HasVoted[client]) {
        ShowWeatherSubmenu(client);
    }
    return 0;
}

public int DynamicWeatherFinalHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));
        ProcessVote(client, "DYNAMIC_WEATHER", info);
    }
    else if (action == MenuAction_Cancel && !g_HasVoted[client]) {
        ShowGameplayDetailSubmenu(client, "weather");
    }
    return 0;
}

public int GameplayFinalHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));
        ProcessVote(client, "GAMEPLAY", info);
        
        // Show individual result
        PrintToChat(client, "\x04[VALVE]\x01 Thank you for voting on: %s", info);
        PrintToChat(client, "\x04[VALVE]\x01 Your feedback has been recorded.");
    }
    else if (action == MenuAction_Cancel && !g_HasVoted[client]) {
        ShowGameplaySubmenu(client);
    }
    return 0;
}

void ShowInfectedSubmenu(int client) {  // Remove the second parameter since we don't need it
    Menu menu = new Menu(InfectedSubmenuHandler);
    menu.SetTitle("╔═══ INFECTED FEATURES ═══╗\n╚════════════════════════╝");
    
    menu.AddItem("► THE CLIMBER\n- Wall scaling\n- Ceiling ambush\n- Web creation", 
                "► THE CLIMBER\n- Wall scaling\n- Ceiling ambush\n- Web creation");
    menu.AddItem("► THE SCREAMER\n- Sonic attacks\n- Horde summoning\n- Disorientation", 
                "► THE SCREAMER\n- Sonic attacks\n- Horde summoning\n- Disorientation");
    menu.AddItem("► THE STALKER\n- Stealth movement\n- Marking targets\n- Pack tactics", 
                "► THE STALKER\n- Stealth movement\n- Marking targets\n- Pack tactics");
    menu.AddItem("► THE BRUTE\n- Heavy damage\n- Area control\n- Survivor separation", 
                "► THE BRUTE\n- Heavy damage\n- Area control\n- Survivor separation");
    menu.AddItem("► THE DIGGER\n- Underground movement\n- Terrain destruction\n- Surprise attacks", 
                "► THE DIGGER\n- Underground movement\n- Terrain destruction\n- Surprise attacks");
    menu.AddItem("► THE SIREN\n- Mind control\n- Area denial\n- Team disruption", 
                "► THE SIREN\n- Mind control\n- Area denial\n- Team disruption");
    
    menu.ExitButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int InfectedFinalHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        char info[32];
        menu.GetItem(param2, info, sizeof(info));
        ProcessVote(client, "INFECTED", info);
        
        // Show individual result
        PrintToChat(client, "\x04[VALVE]\x01 Thank you for voting on: %s", info);
        PrintToChat(client, "\x04[VALVE]\x01 Your feedback has been recorded.");
    }
    else if (action == MenuAction_Cancel && !g_HasVoted[client]) {
        ShowInfectedSubmenu(client);
    }
    return 0;
}

public Action Command_TestL4D3Menu(int client, int args) {
    // Check if valid client
    if (client == 0) {
        ReplyToCommand(client, "[L4D3] This command can only be used in-game.");
        return Plugin_Handled;
    }
    
    // Check if survey is active
    if (!g_SurveyActive) {
        PrintToChat(client, "\x04[VALVE]\x01 The L4D3 survey is currently paused.");
        return Plugin_Handled;
    }
    
    // If they've already voted, show them the current results
    if (g_HasVoted[client]) {
        PrintToChat(client, "\x04[VALVE]\x01 You have already voted. Here are the current results:");
        ShowCurrentResults();
        return Plugin_Handled;
    }
    
    // Reset vote status for testing
    g_HasVoted[client] = false;
    
    // Open the main menu
    ShowL4D3Survey(client);
    
    // Print usage info
    PrintToChat(client, "\x04[VALVE]\x01 L4D3 Survey Menu opened for testing.");
    PrintToChat(client, "\x04[VALVE]\x01 Use !resetvote to test again.");
    
    return Plugin_Handled;
}

public Action Command_ResetVote(int client, int args) {
    if (client == 0) {
        ReplyToCommand(client, "[L4D3] This command can only be used in-game.");
        return Plugin_Handled;
    }
    
    g_HasVoted[client] = false;
    PrintToChat(client, "\x04[VALVE]\x01 Your vote status has been reset. You can test the menu again.");
    
    return Plugin_Handled;
}

void ShowVoteResults() {
    char topFeatures[3][64];
    int topVotes[3];
    GetTopFeatures(topFeatures, topVotes);
    
    PrintToChatAll("\x04[VALVE]\x01 ════════════════════════════");
    PrintToChatAll("\x04[VALVE]\x05 L4D3 SURVEY RESULTS");
    PrintToChatAll("\x04[VALVE]\x01 ════════════════════════════");
    
    for (int i = 0; i < 3; i++) {
        if (topVotes[i] > 0) {
            char description[256];
            GetFeatureDescription(topFeatures[i], description, sizeof(description));
            
            PrintToChatAll("\x04[VALVE]\x05 #%d Most Requested Feature:", i + 1);
            PrintToChatAll("\x04[VALVE]\x03 %s", description);
            PrintToChatAll("\x04[VALVE]\x01 » Total Votes:\x04 %d", topVotes[i]);
            PrintToChatAll("\x04[VALVE]\x01 ────────────────────────────");
        }
    }
    
    PrintToChatAll("\x04[VALVE]\x05 Thank you for helping shape L4D3!");
    PrintToChatAll("\x04[VALVE]\x01 ════════════════════════════");
}

void ProcessVote(int client, const char[] category, const char[] vote) {
    // ... existing broadcast code ...
    
    // Store vote in individual file
    char steamId[64];
    if (GetClientAuthId(client, AuthId_Steam3, steamId, sizeof(steamId), true)) {
        // Clean up Steam ID for filename - remove [U:1:] format to match u11125835381
        ReplaceString(steamId, sizeof(steamId), "[", "");
        ReplaceString(steamId, sizeof(steamId), "]", "");
        ReplaceString(steamId, sizeof(steamId), ":", "");
        ReplaceString(steamId, sizeof(steamId), "U", "u");
        
        char filePath[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, filePath, sizeof(filePath), "data/l4d3_votes/%s.kv", steamId);
        
        KeyValues kv = new KeyValues("PlayerVote");
        kv.SetString("category", category);
        kv.SetString("vote", vote);
        kv.ExportToFile(filePath);
        delete kv;
        
        PrintToServer("[DEBUG] Saving vote to file: %s", filePath);
    }
    
    // Format the vote key exactly as it appears in GetFeatureDescription
    char voteKey[64];
    Format(voteKey, sizeof(voteKey), "%s_%s", category, vote);
    Format(g_PlayerVotes[client], sizeof(g_PlayerVotes[]), voteKey);
    
    // Get player name
    char playerName[MAX_NAME_LENGTH];
    GetClientName(client, playerName, sizeof(playerName));
    
    // Get nice description
    char fullDescription[256];
    GetFeatureDescription(voteKey, fullDescription, sizeof(fullDescription));
    
    // Extract just the title part (before the newline)
    char title[128];
    int newlinePos = StrContains(fullDescription, "\n");
    if (newlinePos != -1) {
        strcopy(title, newlinePos, fullDescription);
    } else {
        strcopy(title, sizeof(title), fullDescription);
    }
    
    // Broadcast the vote to all players (single announcement)
    PrintToChatAll("\x04[VALVE]\x01 ═══════════════════════");
    PrintToChatAll("\x04[VALVE]\x03 %s\x01 has voted for:", playerName);
    PrintToChatAll("\x04[VALVE]\x04 %s", title);
    PrintToChatAll("\x04[VALVE]\x01 ═══════════════════════");
    
    // Simple confirmation for the voter
    PrintToChat(client, "\x04[VALVE]\x03 Your vote has been recorded!");
}

public Action Timer_ShowResults(Handle timer) {
    ShowVoteResults();
    return Plugin_Stop;
}

void GetTopFeatures(char[][] topFeatures, int[] topVotes) {
    // Initialize arrays to track votes
    StringMap voteCount = new StringMap();
    ArrayList features = new ArrayList(64);
    ArrayList votes = new ArrayList();
    
    // Count votes from current players
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && !IsFakeClient(i)) {
            if (g_PlayerVotes[i][0] != '\0') {
                char vote[64];
                strcopy(vote, sizeof(vote), g_PlayerVotes[i]);
                
                int count = 0;
                if (voteCount.GetValue(vote, count)) {
                    voteCount.SetValue(vote, count + 1);
                } else {
                    voteCount.SetValue(vote, 1);
                    features.PushString(vote);
                }
            }
        }
    }
    
    // Count votes from saved files
    char dir[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, dir, sizeof(dir), "data/l4d3_votes");
    DirectoryListing dList = OpenDirectory(dir);
    
    if (dList != null) {
        char filename[64];
        FileType fileType;
        
        while (dList.GetNext(filename, sizeof(filename), fileType)) {
            if (fileType == FileType_File && StrContains(filename, ".kv") != -1) {
                char filePath[PLATFORM_MAX_PATH];
                Format(filePath, sizeof(filePath), "%s/%s", dir, filename);
                
                KeyValues kv = new KeyValues("PlayerVote");
                if (kv.ImportFromFile(filePath)) {
                    char category[32], vote[32], voteKey[64];
                    kv.GetString("category", category, sizeof(category));
                    kv.GetString("vote", vote, sizeof(vote));
                    Format(voteKey, sizeof(voteKey), "%s_%s", category, vote);
                    
                    int count = 0;
                    if (voteCount.GetValue(voteKey, count)) {
                        voteCount.SetValue(voteKey, count + 1);
                    } else {
                        voteCount.SetValue(voteKey, 1);
                        features.PushString(voteKey);
                    }
                }
                delete kv;
            }
        }
        delete dList;
    }
    
    // Convert to sorted arrays
    int size = features.Length;
    for (int i = 0; i < size; i++) {
        char feature[64];
        features.GetString(i, feature, sizeof(feature));
        
        int count = 0;
        voteCount.GetValue(feature, count);
        votes.Push(count);
    }
    
    // Sort by vote count (bubble sort)
    for (int i = 0; i < size - 1; i++) {
        for (int j = 0; j < size - i - 1; j++) {
            if (votes.Get(j) < votes.Get(j + 1)) {
                // Swap votes
                int tempVote = votes.Get(j);
                votes.Set(j, votes.Get(j + 1));
                votes.Set(j + 1, tempVote);
                
                // Swap features
                char tempFeature[64], feature1[64], feature2[64];
                features.GetString(j, feature1, sizeof(feature1));
                features.GetString(j + 1, feature2, sizeof(feature2));
                strcopy(tempFeature, sizeof(tempFeature), feature1);
                features.SetString(j, feature2);
                features.SetString(j + 1, tempFeature);
            }
        }
    }
    
    // Get top 3
    for (int i = 0; i < 3 && i < size; i++) {
        features.GetString(i, topFeatures[i], 64);
        topVotes[i] = votes.Get(i);
    }
    
    // Debug output
    PrintToServer("[L4D3] Found %d total unique votes", size);
    for (int i = 0; i < 3 && i < size; i++) {
        PrintToServer("[L4D3] #%d: %s with %d votes", i + 1, topFeatures[i], topVotes[i]);
    }
    
    // Cleanup
    delete voteCount;
    delete features;
    delete votes;
}

void GetFeatureDescription(const char[] feature, char[] description, int maxlen) {
    // GAMEPLAY Features
    if (StrEqual(feature, "► STEALTH TAKEDOWNS\n- Silent elimination\n- Tactical advantage")) {
        Format(description, maxlen, "► STEALTH TAKEDOWNS\n- Silent elimination\n- Tactical advantage");
    }
    else if (StrEqual(feature, "► PARKOUR SYSTEM\n- Advanced movement\n- Environmental navigation")) {
        Format(description, maxlen, "► PARKOUR SYSTEM\n- Advanced movement\n- Environmental navigation");
    }
    else if (StrEqual(feature, "► PHYSICS ENGINE\n- Realistic impacts\n- Dynamic interactions")) {
        Format(description, maxlen, "► PHYSICS ENGINE\n- Realistic impacts\n- Dynamic interactions");
    }
    else if (StrEqual(feature, "► CRAFTING SYSTEM\n- Resource combination\n- Custom equipment")) {
        Format(description, maxlen, "► CRAFTING SYSTEM\n- Resource combination\n- Custom equipment");
    }
    
    // INFECTED Features
    else if (StrEqual(feature, "► THE CLIMBER\n- Wall scaling\n- Ceiling ambush\n- Web creation")) {
        Format(description, maxlen, "► THE CLIMBER\n- Wall scaling\n- Ceiling ambush\n- Web creation");
    }
    else if (StrEqual(feature, "► THE SCREAMER\n- Sonic attacks\n- Horde summoning\n- Disorientation")) {
        Format(description, maxlen, "► THE SCREAMER\n- Sonic attacks\n- Horde summoning\n- Disorientation");
    }
    else if (StrEqual(feature, "► THE STALKER\n- Stealth movement\n- Marking targets\n- Pack tactics")) {
        Format(description, maxlen, "► THE STALKER\n- Stealth movement\n- Marking targets\n- Pack tactics");
    }
    else if (StrEqual(feature, "► THE BRUTE\n- Heavy damage\n- Area control\n- Survivor separation")) {
        Format(description, maxlen, "► THE BRUTE\n- Heavy damage\n- Area control\n- Survivor separation");
    }
    
    // SURVIVOR Features
    else if (StrEqual(feature, "► FIELD MEDIC\n- Advanced healing\n- Team support\n- Resource creation")) {
        Format(description, maxlen, "► FIELD MEDIC\n- Advanced healing\n- Team support\n- Resource creation");
    }
    else if (StrEqual(feature, "► ASSAULT\n- Combat specialist\n- Weapon mastery\n- Front line focus")) {
        Format(description, maxlen, "► ASSAULT\n- Combat specialist\n- Weapon mastery\n- Front line focus");
    }
    else if (StrEqual(feature, "► ENGINEER\n- Equipment expert\n- Area defense\n- Resource optimization")) {
        Format(description, maxlen, "► ENGINEER\n- Equipment expert\n- Area defense\n- Resource optimization");
    }
    else if (StrEqual(feature, "► SCOUT\n- Fast movement\n- Resource finding\n- Early warning")) {
        Format(description, maxlen, "► SCOUT\n- Fast movement\n- Resource finding\n- Early warning");
    }
    
    // WEAPON Features
    else if (StrEqual(feature, "► WEAPON MODS\n- Customization options\n- Performance upgrades")) {
        Format(description, maxlen, "► WEAPON MODS\n- Customization options\n- Performance upgrades");
    }
    else if (StrEqual(feature, "► MELEE COMBAT\n- Advanced techniques\n- Close combat focus")) {
        Format(description, maxlen, "► MELEE COMBAT\n- Advanced techniques\n- Close combat focus");
    }
    else if (StrEqual(feature, "► SPECIAL AMMO\n- Unique effects\n- Tactical options")) {
        Format(description, maxlen, "► SPECIAL AMMO\n- Unique effects\n- Tactical options");
    }
    else if (StrEqual(feature, "► THROWABLES\n- New equipment\n- Strategic tools")) {
        Format(description, maxlen, "► THROWABLES\n- New equipment\n- Strategic tools");
    }
    
    // MAP Features
    else if (StrEqual(feature, "► DYNAMIC MAPS\n- Random generation\n- Environmental changes")) {
        Format(description, maxlen, "► DYNAMIC MAPS\n- Random generation\n- Environmental changes");
    }
    else if (StrEqual(feature, "► MAP LOCATIONS\n- Diverse settings\n- Unique environments")) {
        Format(description, maxlen, "► MAP LOCATIONS\n- Diverse settings\n- Unique environments");
    }
    else if (StrEqual(feature, "► SECRET AREAS\n- Hidden paths\n- Bonus content")) {
        Format(description, maxlen, "► SECRET AREAS\n- Hidden paths\n- Bonus content");
    }
    else if (StrEqual(feature, "► MAP EVENTS\n- Random encounters\n- Special objectives")) {
        Format(description, maxlen, "► MAP EVENTS\n- Random encounters\n- Special objectives");
    }
    else if (StrEqual(feature, "► WEATHER IMPACT\n- Environmental effects\n- Strategic changes")) {
        Format(description, maxlen, "► WEATHER IMPACT\n- Environmental effects\n- Strategic changes");
    }
    
    // GAMEMODE Features
    else if (StrEqual(feature, "► STORY MODE\n- Campaign structure\n- Character development")) {
        Format(description, maxlen, "► STORY MODE\n- Campaign structure\n- Character development");
    }
    else if (StrEqual(feature, "► VERSUS MODE\n- Competitive play\n- Team balance")) {
        Format(description, maxlen, "► VERSUS MODE\n- Competitive play\n- Team balance");
    }
    else if (StrEqual(feature, "► SURVIVAL MODE\n- Wave defense\n- Resource management")) {
        Format(description, maxlen, "► SURVIVAL MODE\n- Wave defense\n- Resource management");
    }
    else if (StrEqual(feature, "► CHALLENGE MODE\n- Special rulesets\n- Unique rewards")) {
        Format(description, maxlen, "► CHALLENGE MODE\n- Special rulesets\n- Unique rewards");
    }
    
    // SPECIAL INFECTED Features
    else if (StrEqual(feature, "► SPECIAL INFECTED\n- New mutations\n- Unique abilities")) {
        Format(description, maxlen, "► SPECIAL INFECTED\n- New mutations\n- Unique abilities");
    }
    else if (StrEqual(feature, "► BOSS INFECTED\n- Epic encounters\n- Team challenges")) {
        Format(description, maxlen, "► BOSS INFECTED\n- Epic encounters\n- Team challenges");
    }
    
    // If no match found, return the raw key (shouldn't happen with this setup)
    else {
        Format(description, maxlen, "%s", feature);
    }
}

public Action Timer_WelcomeMessage(Handle timer, any client) {
    if (IsClientInGame(client)) {
        PrintToChat(client, "\x04[VALVE]\x01 ════════════════════════════");
        PrintToChat(client, "\x04[VALVE]\x05 Welcome to the L4D3 Survey!");
        PrintToChat(client, "\x04[VALVE]\x01 Type\x03 !l4d3test\x01 to share your feedback.");
        PrintToChat(client, "\x04[VALVE]\x01 ════════════════════════════");
    }
    return Plugin_Stop;
}

public Action Timer_UpdateResults(Handle timer) {
    ShowCurrentResults();
    return Plugin_Continue;
}

void ShowCurrentResults() {
    static char lastTopFeatures[3][64];
    static int lastTopVotes[3];
    
    char topFeatures[3][64];
    int topVotes[3];
    GetTopFeatures(topFeatures, topVotes);
    
    if (topVotes[0] > 0) {
        PrintToChatAll("\x04[VALVE]\x01 CURRENT SURVEY STANDINGS:");
        
        int totalVotes = 0;
        for (int i = 0; i < 3; i++) {
            if (topVotes[i] > 0) totalVotes += topVotes[i];
        }
        
        for (int i = 0; i < 3; i++) {
            if (topVotes[i] > 0) {
                // Check if this feature has already been shown
                bool isDuplicate = false;
                for (int j = 0; j < i; j++) {
                    if (StrEqual(topFeatures[i], topFeatures[j])) {
                        isDuplicate = true;
                        break;
                    }
                }
                
                if (!isDuplicate) {
                    char description[256], title[128];
                    GetFeatureDescription(topFeatures[i], description, sizeof(description));
                    
                    // Get only the title part (before any newline)
                    int newlinePos = StrContains(description, "\n");
                    if (newlinePos != -1) {
                        strcopy(title, newlinePos + 1, description);
                    } else {
                        strcopy(title, sizeof(title), description);
                    }
                    
                    char positionChange[32];
                    bool wasInTop3 = false;
                    for (int j = 0; j < 3; j++) {
                        if (lastTopFeatures[j][0] != '\0' && strcmp(topFeatures[i], lastTopFeatures[j]) == 0) {
                            wasInTop3 = true;
                            if (i < j) {
                                Format(positionChange, sizeof(positionChange), "\x01[\x04↑\x01]");
                            } else if (i > j) {
                                strcopy(positionChange, sizeof(positionChange), "\x01[\x02↓\x01]");
                            }
                            break;
                        }
                    }
                    
                    if (!wasInTop3 && lastTopFeatures[0][0] != '\0') {
                        strcopy(positionChange, sizeof(positionChange), "\x01[\x05NEW\x01]");
                    } else if (positionChange[0] == '\0') {
                        strcopy(positionChange, sizeof(positionChange), "\x01[•]");
                    }
                    
                    float percentage = (float(topVotes[i]) / float(totalVotes)) * 100.0;
                    PrintToChatAll("\x04[VALVE]\x05 #%d:\x03 %s %s", i + 1, title, positionChange);
                    PrintToChatAll("\x04[VALVE]\x01 » Votes:\x04 %d\x01 (\x04%.1f%%\x01)", topVotes[i], percentage);
                }
            }
        }
        
        for (int i = 0; i < 3; i++) {
            strcopy(lastTopFeatures[i], 64, topFeatures[i]);
            lastTopVotes[i] = topVotes[i];
        }
        
        int votedCount = CountTotalVotes();
        PrintToChatAll("\x04[VALVE]\x03 %d\x01 players have voted! Type\x03 !l4d3test\x01 to vote!", votedCount);
    }
}

public Action Command_ToggleSurvey(int client, int args) {
    if (!CheckCommandAccess(client, "sm_togglesurvey", ADMFLAG_ROOT)) {
        ReplyToCommand(client, "[L4D3] You don't have access to this command.");
        return Plugin_Handled;
    }
    
    g_SurveyActive = !g_SurveyActive;
    PrintToChatAll("\x04[VALVE]\x01 The L4D3 survey has been %s.", g_SurveyActive ? "enabled" : "disabled");
    
    return Plugin_Handled;
}

public Action Timer_ShowMenu(Handle timer, any userid) {
    int client = GetClientOfUserId(userid);
    
    // Validate client and check if they still haven't voted
    if (client > 0 && IsClientInGame(client) && !g_HasVoted[client] && g_bFirstJoin[client]) {
        g_bFirstJoin[client] = false;
        
        // Small delay before showing menu
        CreateTimer(1.0, Timer_DelayedMenu, userid);
    }
    
    return Plugin_Stop;
}

public Action Timer_DelayedMenu(Handle timer, any userid) {
    int client = GetClientOfUserId(userid);
    
    if (client > 0 && IsClientInGame(client) && !g_HasVoted[client]) {
        ShowL4D3Survey(client);
    }
    
    return Plugin_Stop;
}

public int BossInfectedDetailHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        char info[256];
        menu.GetItem(param2, info, sizeof(info));
        ProcessVote(client, "BOSS_INFECTED", info);
    }
    else if (action == MenuAction_Cancel && !g_HasVoted[client]) {
        ShowBossInfectedSubmenu(client);
    }
    return 0;
}

public int WeaponDetailHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        char info[256];
        menu.GetItem(param2, info, sizeof(info));
        ProcessVote(client, "WEAPON", info);
    }
    else if (action == MenuAction_Cancel && !g_HasVoted[client]) {
        ShowWeaponSubmenu(client);
    }
    return 0;
}

public int MapDetailHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        char info[256];
        menu.GetItem(param2, info, sizeof(info));
        ProcessVote(client, "MAP", info);
    }
    else if (action == MenuAction_Cancel && !g_HasVoted[client]) {
        ShowMapSubmenu(client);
    }
    return 0;
}

public int SurvivorDetailHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        char info[256];
        menu.GetItem(param2, info, sizeof(info));
        ProcessVote(client, "SURVIVOR", info);
    }
    else if (action == MenuAction_Cancel && !g_HasVoted[client]) {
        ShowSurvivorSubmenu(client);
    }
    return 0;
}

public int InfectedDetailHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        char info[256];
        menu.GetItem(param2, info, sizeof(info));
        ProcessVote(client, "INFECTED", info);
    }
    else if (action == MenuAction_Cancel && !g_HasVoted[client]) {
        ShowInfectedSubmenu(client);
    }
    return 0;
}

void ShowModesDetailSubmenu(int client, const char[] feature) {
    Menu menu = new Menu(ModesDetailHandler);
    menu.SetTitle("╔═══ GAME MODE DETAILS ═══╗\n╚═════════════════════╝");
    
    if (StrEqual(feature, "► STORY MODE\n- Campaign structure\n- Character development")) {
        menu.AddItem("► BRANCHING STORYLINES\n- Multiple endings\n- Character choices\n- Story consequences", 
                    "► BRANCHING STORYLINES\n- Multiple endings\n- Character choices\n- Story consequences");
        menu.AddItem("► CHARACTER PROGRESSION\n- Skill trees\n- Personal missions\n- Unique abilities", 
                    "► CHARACTER PROGRESSION\n- Skill trees\n- Personal missions\n- Unique abilities");
        menu.AddItem("► DYNAMIC NARRATIVES\n- Adaptive story\n- Character relationships\n- Hidden lore", 
                    "► DYNAMIC NARRATIVES\n- Adaptive story\n- Character relationships\n- Hidden lore");
    }
    else if (StrEqual(feature, "► VERSUS MODE\n- Competitive play\n- Team balance")) {
        menu.AddItem("► 8V8 BATTLES\n- Larger teams\n- Strategic coordination\n- Role specialization", 
                    "► 8V8 BATTLES\n- Larger teams\n- Strategic coordination\n- Role specialization");
        menu.AddItem("► OBJECTIVE MODES\n- Territory control\n- Resource gathering\n- Base defense", 
                    "► OBJECTIVE MODES\n- Territory control\n- Resource gathering\n- Base defense");
        menu.AddItem("► COMPETITIVE FEATURES\n- Ranked matches\n- Team tournaments\n- Seasonal events", 
                    "► COMPETITIVE FEATURES\n- Ranked matches\n- Team tournaments\n- Seasonal events");
    }
    else if (StrEqual(feature, "► SURVIVAL MODE\n- Wave defense\n- Resource management")) {
        menu.AddItem("► FORTIFICATION\n- Base building\n- Defense upgrades\n- Resource networks", 
                    "► FORTIFICATION\n- Base building\n- Defense upgrades\n- Resource networks");
        menu.AddItem("► WAVE SYSTEM\n- Dynamic difficulty\n- Special events\n- Boss encounters", 
                    "► WAVE SYSTEM\n- Dynamic difficulty\n- Special events\n- Boss encounters");
        menu.AddItem("► SURVIVAL MECHANICS\n- Day/night cycle\n- Weather impacts\n- Resource raids", 
                    "► SURVIVAL MECHANICS\n- Day/night cycle\n- Weather impacts\n- Resource raids");
    }
    else if (StrEqual(feature, "► CHALLENGE MODE\n- Special rulesets\n- Unique rewards")) {
        menu.AddItem("► WEEKLY CHALLENGES\n- Unique modifiers\n- Special objectives\n- Exclusive rewards", 
                    "► WEEKLY CHALLENGES\n- Unique modifiers\n- Special objectives\n- Exclusive rewards");
        menu.AddItem("► MUTATION SYSTEM\n- Combined game modes\n- Custom rulesets\n- Community events", 
                    "► MUTATION SYSTEM\n- Combined game modes\n- Custom rulesets\n- Community events");
        menu.AddItem("► ACHIEVEMENT HUNTS\n- Special goals\n- Unique cosmetics\n- Leaderboards", 
                    "► ACHIEVEMENT HUNTS\n- Special goals\n- Unique cosmetics\n- Leaderboards");
    }
    
    menu.ExitButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int GameplayDetailHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        char info[256];
        menu.GetItem(param2, info, sizeof(info));
        ProcessVote(client, "GAMEPLAY_DETAIL", info);
    }
    else if (action == MenuAction_Cancel && !g_HasVoted[client]) {
        ShowGameplaySubmenu(client);
    }
    return 0;
}

public int ModesDetailHandler(Menu menu, MenuAction action, int client, int param2) {
    if (action == MenuAction_Select) {
        char info[256];
        menu.GetItem(param2, info, sizeof(info));
        ProcessVote(client, "MODES_DETAIL", info);
    }
    else if (action == MenuAction_Cancel && !g_HasVoted[client]) {
        ShowModesSubmenu(client);
    }
    return 0;
}

public Action Command_L4D3Test(int client, int args) {
    if (!IsValidClient(client))
        return Plugin_Handled;
        
    // Check if they've already voted
    if (g_HasVoted[client]) {
        PrintToChat(client, "\x04[VALVE]\x01 You have already voted!");
        PrintToChat(client, "\x04[VALVE]\x01 Type \x05!resetvote\x01 to vote again.");
        return Plugin_Handled;
    }

    ShowL4D3Survey(client);
    return Plugin_Handled;
}

bool IsValidClient(int client) {
    return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client));
}

int CountTotalVotes() {
    int count = 0;
    char dir[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, dir, sizeof(dir), "data/l4d3_votes");
    DirectoryListing dList = OpenDirectory(dir);
    
    if (dList != null) {
        char filename[64];
        FileType fileType;
        
        while (dList.GetNext(filename, sizeof(filename), fileType)) {
            if (fileType == FileType_File && StrContains(filename, ".kv") != -1) {
                count++;
            }
        }
        delete dList;
    }
    return count;
}