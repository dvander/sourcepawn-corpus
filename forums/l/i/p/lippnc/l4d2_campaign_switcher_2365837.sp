//////////////////////////////////////////
// Automatic Campaign Switcher for L4D2 //
// Version 2.5                        //
// Compiled Nov 4, 2015                //
// Programmed by Chris Pringle          //
//////////////////////////////////////////

/*==================================================================================================

	This plugin was written in response to the server kicking everyone if the vote is not passed
	at the end of the campaign. It will automatically switch to the appropriate map at all the
	points a vote would be automatically called, by the game, to go to the lobby or play again.
	ACS also includes a voting system in which people can vote for their favorite campaign/map
	on a finale or scavenge map.  The winning campaign/map will become the next map the server
	loads.

	Supported Game Modes in Left 4 Dead 2
	
		Coop
		Realism
		Versus
		Team Versus
		Scavenge
		Team Scavenge
		Mutation 1-20
		Community 1-5

	Change Log
		v2.5 (Nov 14, 2015)		- Added 10 more custom campaigns bringing the total to 200 maps
								- Cleaned up code and CVARs
		v2.2 (Oct 19, 2015)		- Added 39 more custom campaigns bringing the total to 195 maps
		v2.1 (Aug 20, 2014)		- Added 72 more custom campaigns bringing the total to 161 maps
		v2.0 (Aug 14, 2014)		- Added 89 custom campaigns
		v1.2.2 (May 21, 2011)	- Added message for new vote winner when a player disconnects
								- Fixed the sound to play to all the players in the game
								- Added a max amount of coop finale map failures cvar
								- Changed the wait time for voting ad from round_start to the 
								  player_left_start_area event 
								- Added the voting sound when the vote menu pops up
		
		v1.2.1 (May 18, 2011)	- Fixed mutation 15 (Versus Survival)
		
		v1.2.0 (May 16, 2011)	- Changed some of the text to be more clear
								- Added timed notifications for the next map
								- Added a cvar for how to advertise the next map
								- Added a cvar for the next map advertisement interval
								- Added a sound to help notify players of a new vote winner
								- Added a cvar to enable/disable sound notification
								- Added a custom wait time for coop game modes
								
		v1.1.0 (May 12, 2011)	- Added a voting system
								- Added error checks if map is not found when switching
								- Added a cvar for enabling/disabling voting system
								- Added a cvar for how to advertise the voting system
								- Added a cvar for time to wait for voting advertisement
								- Added all current Mutation and Community game modes
								
		v1.0.0 (May 5, 2011)	- Initial Release

===================================================================================================*/
/*======================================================================================
#####################             P L U G I N   I N F O             ####################
======================================================================================*/

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION	"v2.5"


//Define the number of campaigns and maps in rotation
#define NUMBER_OF_CAMPAIGNS			208		/* CHANGE TO MATCH THE TOTAL NUMBER OF CAMPAIGNS */
#define NUMBER_OF_SCAVENGE_MAPS		13		/* CHANGE TO MATCH THE TOTAL NUMBER OF SCAVENGE MAPS */

//Define the wait time after round before changing to the next map in each game mode
#define WAIT_TIME_BEFORE_SWITCH_COOP			60.0
#define WAIT_TIME_BEFORE_SWITCH_VERSUS			6.0
#define WAIT_TIME_BEFORE_SWITCH_SCAVENGE		11.0

//Define Game Modes
#define GAMEMODE_UNKNOWN	-1
#define GAMEMODE_COOP 		0
#define GAMEMODE_VERSUS 	1
#define GAMEMODE_SCAVENGE 	2
#define GAMEMODE_SURVIVAL 	3

#define DISPLAY_MODE_DISABLED	0
#define DISPLAY_MODE_HINT		1
#define DISPLAY_MODE_CHAT		2
#define DISPLAY_MODE_MENU		3

#define SOUND_NEW_VOTE_START	"ui/Beep_SynthTone01.wav"
#define SOUND_NEW_VOTE_WINNER	"ui/alert_clink.wav"


//Global Variables

new g_iGameMode;					//Integer to store the gamemode
new g_iRoundEndCounter;				//Round end event counter for versus
new g_iCoopFinaleFailureCount;		//Number of times the Survivors have lost the current finale
new g_iMaxCoopFinaleFailures = 5;	//Amount of times Survivors can fail before ACS switches in coop
new bool:g_bFinaleWon;				//Indicates whether a finale has be beaten or not

//Campaign and map strings/names
new String:g_strCampaignFirstMap[NUMBER_OF_CAMPAIGNS][32];		//Array of maps to switch to
new String:g_strCampaignLastMap[NUMBER_OF_CAMPAIGNS][32];		//Array of maps to switch from
new String:g_strCampaignName[NUMBER_OF_CAMPAIGNS][32];			//Array of names of the campaign
new String:g_strScavengeMap[NUMBER_OF_SCAVENGE_MAPS][32];		//Array of scavenge maps
new String:g_strScavengeMapName[NUMBER_OF_SCAVENGE_MAPS][32];	//Name of scaveenge maps

//Voting Variables
new bool:g_bVotingEnabled = true;							//Tells if the voting system is on
new g_iVotingAdDisplayMode = DISPLAY_MODE_HINT;				//The way to advertise the voting system
new Float:g_fVotingAdDelayTime = 5.0;						//Time to wait before showing advertising
new bool:g_bVoteWinnerSoundEnabled = true;					//Sound plays when vote winner changes
new g_iNextMapAdDisplayMode = DISPLAY_MODE_HINT;			//The way to advertise the next map
new Float:g_fNextMapAdInterval = 600.0;						//Interval for ACS next map advertisement
new bool:g_bClientShownVoteAd[MAXPLAYERS + 1];				//If the client has seen the ad already
new bool:g_bClientVoted[MAXPLAYERS + 1];					//If the client has voted on a map
new g_iClientVote[MAXPLAYERS + 1];							//The value of the clients vote
new g_iWinningMapIndex;										//Winning map/campaign's index
new g_iWinningMapVotes;										//Winning map/campaign's number of votes
new Handle:g_hMenu_Vote[MAXPLAYERS + 1]	= INVALID_HANDLE;	//Handle for each players vote menu

//Console Variables (CVars)
new Handle:g_hCVar_VotingEnabled			= INVALID_HANDLE;
new Handle:g_hCVar_VoteWinnerSoundEnabled	= INVALID_HANDLE;
new Handle:g_hCVar_VotingAdMode				= INVALID_HANDLE;
new Handle:g_hCVar_VotingAdDelayTime		= INVALID_HANDLE;
new Handle:g_hCVar_NextMapAdMode			= INVALID_HANDLE;
new Handle:g_hCVar_NextMapAdInterval		= INVALID_HANDLE;
new Handle:g_hCVar_MaxFinaleFailures		= INVALID_HANDLE;



/*======================================================================================
##################            A C S   M A P   S T R I N G S            #################
========================================================================================
###                                                                                  ###
###      ***  EDIT THESE STRINGS TO CHANGE THE MAP ROTATIONS TO YOUR LIKING  ***     ###
###                                                                                  ###
========================================================================================
###                                                                                  ###
###       Note: The order these strings are stored is important, so make             ###
###             sure these match up or it will not work properly.                    ###
###                                                                                  ###
###       Make all three of the string variables match, for example:                 ###
###                                                                                  ###
###             Format(g_strCampaignFirstMap[1], 32, "c1m1_hotel");                  ###
###             Format(g_strCampaignLastMap[1], 32, "c1m4_atrium");                  ###
###             Format(g_strCampaignName[1], 32, "Dead Center");                     ###
###                                                                                  ###
###       Notice, all of the strings corresponding with [1] in the array match.      ###
###                                                                                  ###
======================================================================================*/

SetupMapStrings()
{	
	//The following three variables are for all game modes except Scavenge.
	
	//*IMPORTANT* Before editing these change NUMBER_OF_CAMPAIGNS near the top 
	//of this plugin to match the total number of campaigns or it will not 
	//loop through all of them when the check is made to change the campaign.
	
	//First Maps of the Campaign
	Format(g_strCampaignFirstMap[0], 32, "l4d2_city17_01");
	Format(g_strCampaignFirstMap[1], 32, "l4d2_stadium1_apartment");
	Format(g_strCampaignFirstMap[2], 32, "srocchurch");
	Format(g_strCampaignFirstMap[3], 32, "hf01_theforest");
	Format(g_strCampaignFirstMap[4], 32, "nt01_mansion");
	Format(g_strCampaignFirstMap[5], 32, "l4d2_bts01_forest");
	Format(g_strCampaignFirstMap[6], 32, "bloodtracks_01");
	Format(g_strCampaignFirstMap[7], 32, "damitdc1");
	Format(g_strCampaignFirstMap[8], 32, "l4d_mic2_trapmentd");
	Format(g_strCampaignFirstMap[9], 32, "l4d_deathaboard01_prison");
	Format(g_strCampaignFirstMap[10], 32, "esc_jailbreak");
	Format(g_strCampaignFirstMap[11], 32, "l4d2_CC_street_d");
	Format(g_strCampaignFirstMap[12], 32, "l4d_fallen01_approach");
	Format(g_strCampaignFirstMap[13], 32, "l4d2_win1");
	Format(g_strCampaignFirstMap[14], 32, "redemptionII-deadstop");
	Format(g_strCampaignFirstMap[15], 32, "AirCrash");
	Format(g_strCampaignFirstMap[16], 32, "l4d_ihm01_forest");
	Format(g_strCampaignFirstMap[17], 32, "l4d_149_1");
	Format(g_strCampaignFirstMap[18], 32, "l4d2_diescraper1_apartment_35");
	Format(g_strCampaignFirstMap[19], 32, "C1_mario1_1");
	Format(g_strCampaignFirstMap[20], 32, "l4d_noe1");
	Format(g_strCampaignFirstMap[21], 32, "gr-mapone-7");
	Format(g_strCampaignFirstMap[22], 32, "p84m1_crash");
	Format(g_strCampaignFirstMap[23], 32, "qe_1_cliche");
	Format(g_strCampaignFirstMap[24], 32, "l4d2_ravenholmwar_1");
	Format(g_strCampaignFirstMap[25], 32, "uf1_boulevard");
	Format(g_strCampaignFirstMap[26], 32, "l4d_viennacalling_city");
	Format(g_strCampaignFirstMap[27], 32, "l4d_viennacalling2_1");
	Format(g_strCampaignFirstMap[28], 32, "2ee_01");
	Format(g_strCampaignFirstMap[29], 32, "hotel01_market_two");
	Format(g_strCampaignFirstMap[30], 32, "l4d_draxmap0");
	Format(g_strCampaignFirstMap[31], 32, "ddg1_tower_v2_1");
	Format(g_strCampaignFirstMap[32], 32, "deadbeat01_forest");
	Format(g_strCampaignFirstMap[33], 32, "gasfever_1");
	Format(g_strCampaignFirstMap[34], 32, "part1_facility");
	Format(g_strCampaignFirstMap[35], 32, "l4d_yama_1");
	Format(g_strCampaignFirstMap[36], 32, "l4d_doom0001_base");
	Format(g_strCampaignFirstMap[37], 32, "rh_map01");
	Format(g_strCampaignFirstMap[38], 32, "l4d_5tolife01");
	Format(g_strCampaignFirstMap[39], 32, "l4d2_darkblood01_tanker");
	Format(g_strCampaignFirstMap[40], 32, "l4d2_fallindeath01");
	Format(g_strCampaignFirstMap[41], 32, "l4d2_draxmap1");
	Format(g_strCampaignFirstMap[42], 32, "l4d_withoutname_complex");
	Format(g_strCampaignFirstMap[43], 32, "youcallthatalanding");
	Format(g_strCampaignFirstMap[44], 32, "l4d_stranded01_chopper_down");
	Format(g_strCampaignFirstMap[45], 32, "l4dblackoutbasement1");
	Format(g_strCampaignFirstMap[46], 32, "c5m1_darkwaterfront");
	Format(g_strCampaignFirstMap[47], 32, "l4d_dbd2dc_anna_is_gone");
	Format(g_strCampaignFirstMap[48], 32, "l4d2_scream01_yards");
	Format(g_strCampaignFirstMap[49], 32, "wth_1");
	Format(g_strCampaignFirstMap[50], 32, "soi_m1_metrostation");
	Format(g_strCampaignFirstMap[51], 32, "TheCure001");
	Format(g_strCampaignFirstMap[52], 32, "x1m1_cliffs");
	Format(g_strCampaignFirstMap[53], 32, "l4d2_coaldblood01");
	Format(g_strCampaignFirstMap[54], 32, "l4d2_pasiri1");
	Format(g_strCampaignFirstMap[55], 32, "cwm1_intro");
	Format(g_strCampaignFirstMap[56], 32, "beldurra01_urbanbrawl");
	Format(g_strCampaignFirstMap[57], 32, "cbm1_lake");
	Format(g_strCampaignFirstMap[58], 32, "l4d_powerstation_utg_01");
	Format(g_strCampaignFirstMap[59], 32, "l4d2_base_east");
	Format(g_strCampaignFirstMap[60], 32, "uz_crash");
	Format(g_strCampaignFirstMap[61], 32, "l4d2_motamap_m1");
	Format(g_strCampaignFirstMap[62], 32, "bhm1_outskirts");
	Format(g_strCampaignFirstMap[63], 32, "bp_mapalpha1");
	Format(g_strCampaignFirstMap[64], 32, "cfreepassagem1");
	Format(g_strCampaignFirstMap[65], 32, "newintro_3");
	Format(g_strCampaignFirstMap[66], 32, "lost01_club");
	Format(g_strCampaignFirstMap[67], 32, "l4d_lambda_01");
	Format(g_strCampaignFirstMap[68], 32, "saltwell_1_d");
	Format(g_strCampaignFirstMap[69], 32, "Dead_Series1");
	Format(g_strCampaignFirstMap[70], 32, "de01_sewers");
	Format(g_strCampaignFirstMap[71], 32, "l4d2_7hours_later_01");
	Format(g_strCampaignFirstMap[72], 32, "c1m4_atrium");
	Format(g_strCampaignFirstMap[73], 32, "c2m1_highway");
	Format(g_strCampaignFirstMap[74], 32, "c3m1_plankcountry");
	Format(g_strCampaignFirstMap[75], 32, "c4m1_milltown_a");
	Format(g_strCampaignFirstMap[76], 32, "c5m1_waterfront");
	Format(g_strCampaignFirstMap[77], 32, "c6m1_riverbank");
	Format(g_strCampaignFirstMap[78], 32, "c7m1_docks");
	Format(g_strCampaignFirstMap[79], 32, "c8m1_apartment");
	Format(g_strCampaignFirstMap[80], 32, "c9m1_alleys");
	Format(g_strCampaignFirstMap[81], 32, "c10m1_caves");
	Format(g_strCampaignFirstMap[82], 32, "c11m1_greenhouse");
	Format(g_strCampaignFirstMap[83], 32, "c12m1_hilltop");
	Format(g_strCampaignFirstMap[84], 32, "c13m1_alpinecreek");
	Format(g_strCampaignFirstMap[85], 32, "l4d2_downtowndine01");
	Format(g_strCampaignFirstMap[86], 32, "l4d2_deathwoods01_stranded");
	Format(g_strCampaignFirstMap[87], 32, "l4d_greyscale_01_street");
	Format(g_strCampaignFirstMap[88], 32, "gb_m1_road");
	Format(g_strCampaignFirstMap[89], 32, "highway01_apt_20130613");
	Format(g_strCampaignFirstMap[90], 32, "l4d2_sbtd_01");
	Format(g_strCampaignFirstMap[91], 32, "l4d_cctf1");
	Format(g_strCampaignFirstMap[92], 32, "Gasometer");
	Format(g_strCampaignFirstMap[93], 32, "eu01_residential_b16");
	Format(g_strCampaignFirstMap[94], 32, "jsarena201_town");
	Format(g_strCampaignFirstMap[95], 32, "jsgone01_crash");
	Format(g_strCampaignFirstMap[96], 32, "SpaceJockeysbackup");
	Format(g_strCampaignFirstMap[97], 32, "WormwoodVnew");
	Format(g_strCampaignFirstMap[98], 32, "titty1");
	Format(g_strCampaignFirstMap[99], 32, "indiana_adventure1");
	Format(g_strCampaignFirstMap[100], 32, "l4d_bureaux");
	Format(g_strCampaignFirstMap[101], 32, "l4d_almacen001_almacen");
	Format(g_strCampaignFirstMap[102], 32, "ud_map01_n");
	Format(g_strCampaignFirstMap[103], 32, "l4d2_deadcity01_riverside");
	Format(g_strCampaignFirstMap[104], 32, "l4d2_scream01_yards");
	Format(g_strCampaignFirstMap[105], 32, "l4d2_deathtoll01_clam");
	Format(g_strCampaignFirstMap[106], 32, "DthMnt_Village");
	Format(g_strCampaignFirstMap[107], 32, "tlv01_city");
	Format(g_strCampaignFirstMap[108], 32, "ulice");
	Format(g_strCampaignFirstMap[109], 32, "tunel");
	Format(g_strCampaignFirstMap[110], 32, "bha01");
	Format(g_strCampaignFirstMap[111], 32, "alejki");
	Format(g_strCampaignFirstMap[112], 32, "las");
	Format(g_strCampaignFirstMap[113], 32, "l4d_pdmesa01_surface");
	Format(g_strCampaignFirstMap[114], 32, "l4d_noway_streets01");
	Format(g_strCampaignFirstMap[115], 32, "l4d_linz_kbh");
	Format(g_strCampaignFirstMap[116], 32, "mall_of_ukraine");
	Format(g_strCampaignFirstMap[117], 32, "l4d_tbm_1");
	Format(g_strCampaignFirstMap[118], 32, "l4d2_ic_1_city");
	Format(g_strCampaignFirstMap[119], 32, "l4d2_ic2_5");
	Format(g_strCampaignFirstMap[120], 32, "hideout01_v5");
	Format(g_strCampaignFirstMap[121], 32, "zmb13_m1_barracks");
	Format(g_strCampaignFirstMap[122], 32, "tacobucket01");
	Format(g_strCampaignFirstMap[123], 32, "l4d2_sbtd_01");
	Format(g_strCampaignFirstMap[124], 32, "l4d_deathrow01_streets");
	Format(g_strCampaignFirstMap[125], 32, "dead_death_02");
	Format(g_strCampaignFirstMap[126], 32, "l4d_suburb01_school");
	Format(g_strCampaignFirstMap[127], 32, "l4d2_dm_01");
	Format(g_strCampaignFirstMap[128], 32, "l4d_cc1");
	Format(g_strCampaignFirstMap[129], 32, "l4d2_scream01_yards");
	Format(g_strCampaignFirstMap[130], 32, "l4d_cine");
	Format(g_strCampaignFirstMap[131], 32, "l4d_deadgetaway01_dam");
	Format(g_strCampaignFirstMap[132], 32, "l4d_noway_out_town");
	Format(g_strCampaignFirstMap[133], 32, "tbm_survivor_01");
	Format(g_strCampaignFirstMap[134], 32, "rmstitanic_m1");
	Format(g_strCampaignFirstMap[135], 32, "mrr_01_darkforest");
	Format(g_strCampaignFirstMap[136], 32, "l4d_zero01_base");
	Format(g_strCampaignFirstMap[137], 32, "outback#rail");
	Format(g_strCampaignFirstMap[138], 32, "blood_hospital_01");
	Format(g_strCampaignFirstMap[139], 32, "l4d2_farm01_hilltop");
	Format(g_strCampaignFirstMap[140], 32, "l4d_bs_mansion");
	Format(g_strCampaignFirstMap[141], 32, "carnage_jail");
	Format(g_strCampaignFirstMap[142], 32, "claustrophobia1");
	Format(g_strCampaignFirstMap[143], 32, "l4d_coldfear01_smallforest");
	Format(g_strCampaignFirstMap[144], 32, "l4d2_deadstreet_obahn");
	Format(g_strCampaignFirstMap[145], 32, "shopcenter");
	Format(g_strCampaignFirstMap[146], 32, "c1_1_mall");
	Format(g_strCampaignFirstMap[147], 32, "left4bowl_depot");
	Format(g_strCampaignFirstMap[148], 32, "m1_village");
	Format(g_strCampaignFirstMap[149], 32, "Bus_Depot");
	Format(g_strCampaignFirstMap[150], 32, "l4d_arrival");
	Format(g_strCampaignFirstMap[151], 32, "l4d2_Prototype_Mk3_1");
	Format(g_strCampaignFirstMap[152], 32, "l4d2_deadflagblues01_city");
	Format(g_strCampaignFirstMap[153], 32, "l4d2-DisposalFacility");
	Format(g_strCampaignFirstMap[154], 32, "intro");
	Format(g_strCampaignFirstMap[155], 32, "l4d_coaldblood01");
	Format(g_strCampaignFirstMap[156], 32, "kap_chinadocks");
	Format(g_strCampaignFirstMap[157], 32, "cc1m1_crash");
	Format(g_strCampaignFirstMap[158], 32, "l4d2_deathcraft_01_town");
	Format(g_strCampaignFirstMap[159], 32, "l4d_eft1_subsystem");
	Format(g_strCampaignFirstMap[160], 32, "l4d2_roadtonowhere_route01");
	Format(g_strCampaignFirstMap[161], 32, "cdta_01detour");
	Format(g_strCampaignFirstMap[162], 32, "l4d2_garage01_alleys_a");
	Format(g_strCampaignFirstMap[163], 32, "Underground3");
	Format(g_strCampaignFirstMap[164], 32, "damshort170surv");
	Format(g_strCampaignFirstMap[165], 32, "c1m1d_hotel");
	Format(g_strCampaignFirstMap[166], 32, "port_01");
	Format(g_strCampaignFirstMap[167], 32, "death_sentence_1");
	Format(g_strCampaignFirstMap[168], 32, "BadHoodL1");
	Format(g_strCampaignFirstMap[169], 32, "01_de_trainyard");
	Format(g_strCampaignFirstMap[170], 32, "route_to_city_vs1");
	Format(g_strCampaignFirstMap[171], 32, "NewRise");
	Format(g_strCampaignFirstMap[172], 32, "l4d2_echo");
	Format(g_strCampaignFirstMap[173], 32, "dprm1_milltown_a");
	Format(g_strCampaignFirstMap[174], 32, "the_hive_m1");
	Format(g_strCampaignFirstMap[175], 32, "orc001");
	Format(g_strCampaignFirstMap[176], 32, "1_nemesis_uptown");
	Format(g_strCampaignFirstMap[177], 32, "npi_heartbreakfridgemap1");
	Format(g_strCampaignFirstMap[178], 32, "l4d_MIC2_TrapmentD");
	Format(g_strCampaignFirstMap[179], 32, "l4d2_kinkm1");
	Format(g_strCampaignFirstMap[180], 32, "dw_woods");
	Format(g_strCampaignFirstMap[181], 32, "splash1");
	Format(g_strCampaignFirstMap[182], 32, "tacobucket01");
	Format(g_strCampaignFirstMap[183], 32, "l4d2_ff01_woods");
	Format(g_strCampaignFirstMap[184], 32, "potc1");
	Format(g_strCampaignFirstMap[185], 32, "exmala1_1");
	Format(g_strCampaignFirstMap[186], 32, "the_tunnels");
	Format(g_strCampaignFirstMap[187], 32, "l4d2_dead_end");
	Format(g_strCampaignFirstMap[188], 32, "l4d_bureaux");
	Format(g_strCampaignFirstMap[189], 32, "grmap1");
	Format(g_strCampaignFirstMap[190], 32, "l4d_co_canal");
	Format(g_strCampaignFirstMap[191], 32, "reintro");
	Format(g_strCampaignFirstMap[192], 32, "l4d2_daybreak01_hotel");
	Format(g_strCampaignFirstMap[193], 32, "ec01_outlets");
	Format(g_strCampaignFirstMap[194], 32, "l4d_naniwa01_shoppingmall");
	Format(g_strCampaignFirstMap[195], 32, "apartment");
	Format(g_strCampaignFirstMap[196], 32, "hellishjourney01");
	Format(g_strCampaignFirstMap[197], 32, "l4d_derailed_highway2ver");
	Format(g_strCampaignFirstMap[198], 32, "l4d2_camp_dead");
	Format(g_strCampaignFirstMap[199], 32, "silent_hillbc");
	Format(g_strCampaignFirstMap[200], 32, "patientscab");
	Format(g_strCampaignFirstMap[201], 32, "desperate_houseway");
	Format(g_strCampaignFirstMap[202], 32, "l4d_auburn");
	Format(g_strCampaignFirstMap[203], 32, "the_return_lvl1");
	Format(g_strCampaignFirstMap[204], 32, "a_lor_11");
	Format(g_strCampaignFirstMap[205], 32, "a_lor_11");
	Format(g_strCampaignFirstMap[206], 32, "a_lor_11");
	Format(g_strCampaignFirstMap[207], 32, "l4d2_auburn");
	
	//Last Maps of the Campaign
	Format(g_strCampaignLastMap[0], 32, "l4d2_city17_05");
	Format(g_strCampaignLastMap[1], 32, "l4d2_stadium5_stadium");
	Format(g_strCampaignLastMap[2], 32, "mnac");
	Format(g_strCampaignLastMap[3], 32, "hf04_escape");
	Format(g_strCampaignLastMap[4], 32, "nt05_wake");
	Format(g_strCampaignLastMap[5], 32, "l4d2_bts06_school");
	Format(g_strCampaignLastMap[6], 32, "bloodtracks_04");
	Format(g_strCampaignLastMap[7], 32, "damitdc4");
	Format(g_strCampaignLastMap[8], 32, "l4d_mic_finale");
	Format(g_strCampaignLastMap[9], 32, "l4d_deathaboard05_light");
	Format(g_strCampaignLastMap[10], 32, "esc_fly_me_to_the_moon");
	Format(g_strCampaignLastMap[11], 32, "l4d2_cc_finale");
	Format(g_strCampaignLastMap[12], 32, "l4d_fallen05_shaft");
	Format(g_strCampaignLastMap[13], 32, "l4d2_win6");
	Format(g_strCampaignLastMap[14], 32, "roundhouse");
	Format(g_strCampaignLastMap[15], 32, "BombShelter");
	Format(g_strCampaignLastMap[16], 32, "l4d_ihm05_lakeside");
	Format(g_strCampaignLastMap[17], 32, "l4d_149_5");
	Format(g_strCampaignLastMap[18], 32, "l4d2_diescraper4_top_35");
	Format(g_strCampaignLastMap[19], 32, "C1_mario1_4");
	Format(g_strCampaignLastMap[20], 32, "l4d_noe3");
	Format(g_strCampaignLastMap[21], 32, "gasrun");
	Format(g_strCampaignLastMap[22], 32, "p84m4_precinct");
	Format(g_strCampaignLastMap[23], 32, "qe_4_ultimate_test");
	Format(g_strCampaignLastMap[24], 32, "l4d2_ravenholmwar_4");
	Format(g_strCampaignLastMap[25], 32, "uf4_airfield");
	Format(g_strCampaignLastMap[26], 32, "l4d_viennacalling_donauturm");
	Format(g_strCampaignLastMap[27], 32, "l4d_viennacalling2_finale");
	Format(g_strCampaignLastMap[28], 32, "2ee_06");
	Format(g_strCampaignLastMap[29], 32, "hotel05_rooftop_two");
	Format(g_strCampaignLastMap[30], 32, "l4d_draxmap4");
	Format(g_strCampaignLastMap[31], 32, "ddg3_bluff_v2_1");
	Format(g_strCampaignLastMap[32], 32, "deadbeat04_park");
	Format(g_strCampaignLastMap[33], 32, "gasfever_3");
	Format(g_strCampaignLastMap[34], 32, "part4_cradle");
	Format(g_strCampaignLastMap[35], 32, "l4d_yama_5");
	Format(g_strCampaignLastMap[36], 32, "l4d_doom03_ballroom");
	Format(g_strCampaignLastMap[37], 32, "rh_map05");
	Format(g_strCampaignLastMap[38], 32, "l4d_5tolife03");
	Format(g_strCampaignLastMap[39], 32, "l4d2_darkblood04_extraction");
	Format(g_strCampaignLastMap[40], 32, "l4d2_fallindeath04");
	Format(g_strCampaignLastMap[41], 32, "l4d2_draxmap6");
	Format(g_strCampaignLastMap[42], 32, "l4d_withoutname_town");
	Format(g_strCampaignLastMap[43], 32, "GoingUp");
	Format(g_strCampaignLastMap[44], 32, "l4d_stranded05_park_final");
	Format(g_strCampaignLastMap[45], 32, "l4dblackoutbasement4");
	Format(g_strCampaignLastMap[46], 32, "c5m5_darkbridge");
	Format(g_strCampaignLastMap[47], 32, "l4d_dbd2_new_dawn");
	Format(g_strCampaignLastMap[48], 32, "l4d2_scream05_finale");
	Format(g_strCampaignLastMap[49], 32, "wth_5");
	Format(g_strCampaignLastMap[50], 32, "soi_m4_underground");
	Format(g_strCampaignLastMap[51], 32, "TheCure005");
	Format(g_strCampaignLastMap[52], 32, "x1m5_salvation");
	Format(g_strCampaignLastMap[53], 32, "l4d2_coaldblood06");
	Format(g_strCampaignLastMap[54], 32, "l4d2_pasiri4");
	Format(g_strCampaignLastMap[55], 32, "cwm4_building");
	Format(g_strCampaignLastMap[56], 32, "beldurra03_riverside");
	Format(g_strCampaignLastMap[57], 32, "cbm3_bunker");
	Format(g_strCampaignLastMap[58], 32, "l4d_powerstation_utg_05");
	Format(g_strCampaignLastMap[59], 32, "l4d2_base_escape");
	Format(g_strCampaignLastMap[60], 32, "uz_escape");
	Format(g_strCampaignLastMap[61], 32, "l4d2_motamap_m5");
	Format(g_strCampaignLastMap[62], 32, "bhm4_base");
	Format(g_strCampaignLastMap[63], 32, "bp_map_03");
	Format(g_strCampaignLastMap[64], 32, "cfreepassagem3");
	Format(g_strCampaignLastMap[65], 32, "new_lava_weather_3");
	Format(g_strCampaignLastMap[66], 32, "lost02_2");
	Format(g_strCampaignLastMap[67], 32, "l4d_lambda_09");
	Format(g_strCampaignLastMap[68], 32, "saltwell_5_d");
	Format(g_strCampaignLastMap[69], 32, "Dead_Series4");
	Format(g_strCampaignLastMap[70], 32, "de05_echo_finale");
	Format(g_strCampaignLastMap[71], 32, "l4d2_7hours_later_05");
	Format(g_strCampaignLastMap[72], 32, "c1m4_atrium");
	Format(g_strCampaignLastMap[73], 32, "c2m5_concert");
	Format(g_strCampaignLastMap[74], 32, "c3m4_plantation");
	Format(g_strCampaignLastMap[75], 32, "c4m5_milltown_escape");
	Format(g_strCampaignLastMap[76], 32, "c5m5_bridge");
	Format(g_strCampaignLastMap[77], 32, "c6m3_port");
	Format(g_strCampaignLastMap[78], 32, "c7m3_port");
	Format(g_strCampaignLastMap[79], 32, "c8m5_rooftop");
	Format(g_strCampaignLastMap[80], 32, "c9m2_lots");
	Format(g_strCampaignLastMap[81], 32, "c10m5_houseboat");
	Format(g_strCampaignLastMap[82], 32, "c11m5_runway");
	Format(g_strCampaignLastMap[83], 32, "c12m5_cornfield");
	Format(g_strCampaignLastMap[84], 32, "c13m4_cutthroatcreek");
	Format(g_strCampaignLastMap[85], 32, "l4d2_downtowndine05");
	Format(g_strCampaignLastMap[86], 32, "l4d2_deathwoods05_airfield");
	Format(g_strCampaignLastMap[87], 32, "l4d_greyscale_04_rooftop");
	Format(g_strCampaignLastMap[88], 32, "gb_m5_burn");
	Format(g_strCampaignLastMap[89], 32, "highway05_afb02_20130820");
	Format(g_strCampaignLastMap[90], 32, "l4d2_sbtd_03");
	Format(g_strCampaignLastMap[91], 32, "l4d_cctf5");
	Format(g_strCampaignLastMap[92], 32, "Centro_Final");
	Format(g_strCampaignLastMap[93], 32, "eu05_train_b16");
	Format(g_strCampaignLastMap[94], 32, "jsarena204_arena");
	Format(g_strCampaignLastMap[95], 32, "jsgone02_end");
	Format(g_strCampaignLastMap[96], 32, "SpaceJockeysbackup");
	Format(g_strCampaignLastMap[97], 32, "WormwoodVnew");
	Format(g_strCampaignLastMap[98], 32, "titty");
	Format(g_strCampaignLastMap[99], 32, "indiana_adventure_whole");
	Format(g_strCampaignLastMap[100], 32, "l4d_le_parc");
	Format(g_strCampaignLastMap[101], 32, "l4d_almacen005_fabrica");
	Format(g_strCampaignLastMap[102], 32, "ud_map05");
	Format(g_strCampaignLastMap[103], 32, "l4d2_deadcity06_station");
	Format(g_strCampaignLastMap[104], 32, "l4d2_scream05_finale");
	Format(g_strCampaignLastMap[105], 32, "l4d2_deathtoll05_clam");
	Format(g_strCampaignLastMap[106], 32, "DthMnt_TempleBoss");
	Format(g_strCampaignLastMap[107], 32, "tlv03_riverside");
	Format(g_strCampaignLastMap[108], 32, "dach");
	Format(g_strCampaignLastMap[109], 32, "domki");
	Format(g_strCampaignLastMap[110], 32, "rombu05");
	Format(g_strCampaignLastMap[111], 32, "baza2");
	Format(g_strCampaignLastMap[112], 32, "Lotnisko");
	Format(g_strCampaignLastMap[113], 32, "l4d_pdmesa05_returntoxen");
	Format(g_strCampaignLastMap[114], 32, "l4d_noway_market03");
	Format(g_strCampaignLastMap[115], 32, "l4d_linz_bahnhof");
	Format(g_strCampaignLastMap[116], 32, "the_end");
	Format(g_strCampaignLastMap[117], 32, "l4d_tbm_5");
	Format(g_strCampaignLastMap[118], 32, "l4d2_ic_5_Finale");
	Format(g_strCampaignLastMap[119], 32, "l4d2_ic_2_1");
	Format(g_strCampaignLastMap[120], 32, "hideout04_v2");
	Format(g_strCampaignLastMap[121], 32, "zmb13_m3_surface");
	Format(g_strCampaignLastMap[122], 32, "tacobucket03");
	Format(g_strCampaignLastMap[123], 32, "l4d2_sbtd_03");
	Format(g_strCampaignLastMap[124], 32, "l4d_deathrow04_courtyard");
	Format(g_strCampaignLastMap[125], 32, "l4d_the_complex_final_03");
	Format(g_strCampaignLastMap[126], 32, "l4d_suburb03_neighborhood");
	Format(g_strCampaignLastMap[127], 32, "l4d2_dm_08");
	Format(g_strCampaignLastMap[128], 32, "l4d_cc5");
	Format(g_strCampaignLastMap[129], 32, "l4d2_scream05_finale");
	Format(g_strCampaignLastMap[130], 32, "l4d_ruinas");
	Format(g_strCampaignLastMap[131], 32, "l4d_deadgetaway_final");
	Format(g_strCampaignLastMap[132], 32, "l4d_noway_out3");
	Format(g_strCampaignLastMap[133], 32, "tbm_survivor_03");
	Format(g_strCampaignLastMap[134], 32, "rmstitanic_m4");
	Format(g_strCampaignLastMap[135], 32, "mrr_04_stationfinale");
	Format(g_strCampaignLastMap[136], 32, "l4d_zero05_villa");
	Format(g_strCampaignLastMap[137], 32, "dockss2");
	Format(g_strCampaignLastMap[138], 32, "blood_hospital_03");
	Format(g_strCampaignLastMap[139], 32, "l4d2_farm05_cornfield_heli");
	Format(g_strCampaignLastMap[140], 32, "l4d_bs_bloodyfinale1");
	Format(g_strCampaignLastMap[141], 32, "carnage_warehouse");
	Format(g_strCampaignLastMap[142], 32, "claustrophobia7");
	Format(g_strCampaignLastMap[143], 32, "l4d_coldfear05_docks");
	Format(g_strCampaignLastMap[144], 32, "l4d2_deadstreet_thepark");
	Format(g_strCampaignLastMap[145], 32, "school");
	Format(g_strCampaignLastMap[146], 32, "c1_4_roof_safe");
	Format(g_strCampaignLastMap[147], 32, "left4bowl_escape");
	Format(g_strCampaignLastMap[148], 32, "m4_ruins");
	Format(g_strCampaignLastMap[149], 32, "EngineRoom");
	Format(g_strCampaignLastMap[150], 32, "l4d_marsbase");
	Format(g_strCampaignLastMap[151], 32, "l4d2_prototype_Mk3_5");
	Format(g_strCampaignLastMap[152], 32, "l4d2_deadflagblues05_station");
	Format(g_strCampaignLastMap[153], 32, "l4d2_UndergorundBase");
	Format(g_strCampaignLastMap[154], 32, "canalpark");
	Format(g_strCampaignLastMap[155], 32, "l4d_coaldBlood04");
	Format(g_strCampaignLastMap[156], 32, "kap_chinafinale");
	Format(g_strCampaignLastMap[157], 32, "cc1m2_rush");
	Format(g_strCampaignLastMap[158], 32, "l4d2_minecraft_evolution");
	Format(g_strCampaignLastMap[159], 32, "l4d_eft6_bordercrossing1");
	Format(g_strCampaignLastMap[160], 32, "l4d2_roadtonowhere_route06");
	Format(g_strCampaignLastMap[161], 32, "cdta_05finalroad");
	Format(g_strCampaignLastMap[162], 32, "l4d2_garage01_alleys_escape");
	Format(g_strCampaignLastMap[163], 32, "RomanFortInvert");
	Format(g_strCampaignLastMap[164], 32, "gemarshy03aztec");
	Format(g_strCampaignLastMap[165], 32, "c1m4d_atrium");
	Format(g_strCampaignLastMap[166], 32, "outpost_3");
	Format(g_strCampaignLastMap[167], 32, "death_sentence_5");
	Format(g_strCampaignLastMap[168], 32, "BadHoodL4");
	Format(g_strCampaignLastMap[169], 32, "04_de_deadly_ending");
	Format(g_strCampaignLastMap[170], 32, "trainstation21");
	Format(g_strCampaignLastMap[171], 32, "NewRiseMapFinale");
	Format(g_strCampaignLastMap[172], 32, "l4d2_hub");
	Format(g_strCampaignLastMap[173], 32, "dprm5_milltown_escape");
	Format(g_strCampaignLastMap[174], 32, "the_hive_m5");
	Format(g_strCampaignLastMap[175], 32, "orc003");
	Format(g_strCampaignLastMap[176], 32, "7_nemesis_finale");
	Format(g_strCampaignLastMap[177], 32, "npi_meatlockermapd");
	Format(g_strCampaignLastMap[178], 32, "l4d_mic2_Inter_Vention");
	Format(g_strCampaignLastMap[179], 32, "l4d2_kinkm4");
	Format(g_strCampaignLastMap[180], 32, "dw_final");
	Format(g_strCampaignLastMap[181], 32, "splash5");
	Format(g_strCampaignLastMap[182], 32, "convoyturtorial-100");
	Format(g_strCampaignLastMap[183], 32, "l4d2_ff05_station");
	Format(g_strCampaignLastMap[184], 32, "potc4");
	Format(g_strCampaignLastMap[185], 32, "exmala1_3");
	Format(g_strCampaignLastMap[186], 32, "the_bitter_end");
	Format(g_strCampaignLastMap[187], 32, "l4d2_dead_end_part3");
	Format(g_strCampaignLastMap[188], 32, "l4d_le_parc");
	Format(g_strCampaignLastMap[189], 32, "grid4");
	Format(g_strCampaignLastMap[190], 32, "l4d_co_bridge");
	Format(g_strCampaignLastMap[191], 32, "re_decisionsfinale");
	Format(g_strCampaignLastMap[192], 32, "l4d2_daybreak05_rescue");
	Format(g_strCampaignLastMap[193], 32, "ec05_quarry");
	Format(g_strCampaignLastMap[194], 32, "l4d_naniwa05_tower");
	Format(g_strCampaignLastMap[195], 32, "station");
	Format(g_strCampaignLastMap[196], 32, "hellishjourney04");
	Format(g_strCampaignLastMap[197], 32, "l4d_derailed_finale2ver");
	Format(g_strCampaignLastMap[198], 32, "l4d2_death_pit_finale");
	Format(g_strCampaignLastMap[199], 32, "silent_hill5bc");
	Format(g_strCampaignLastMap[200], 32, "l4d_babel_finalcab");
	Format(g_strCampaignLastMap[201], 32, "band_of_rushers");
	Format(g_strCampaignLastMap[202], 32, "l4d_auburn_finale");
	Format(g_strCampaignLastMap[203], 32, "the_return_lvl5");
	Format(g_strCampaignLastMap[204], 32, "a_lor_41");
	Format(g_strCampaignLastMap[205], 32, "a_lor_42");
	Format(g_strCampaignLastMap[206], 32, "a_lor_43");
	Format(g_strCampaignLastMap[207], 32, "l4d2_auburn_3new");
	
	//Campaign Names
	Format(g_strCampaignName[0], 32, "City 17 v3.2");
	Format(g_strCampaignName[1], 32, "Suicide Blitz 2");
	Format(g_strCampaignName[2], 32, "Warecelona");
	Format(g_strCampaignName[3], 32, "Haunted Forest");
	Format(g_strCampaignName[4], 32, "Night Terror");
	Format(g_strCampaignName[5], 32, "Back To School");
	Format(g_strCampaignName[6], 32, "Blood Tracks");
	Format(g_strCampaignName[7], 32, "Damit 2! DC");
	Format(g_strCampaignName[8], 32, "Military Industrial Complex III v666");
	Format(g_strCampaignName[9], 32, "Death Aboard II");
	Format(g_strCampaignName[10], 32, "Escansion");
	Format(g_strCampaignName[11], 32, "City Center Apocalypse");
	Format(g_strCampaignName[12], 32, "Fallen L4D2");
	Format(g_strCampaignName[13], 32, "Freezer Burn");
	Format(g_strCampaignName[14], 32, "RedemptionII");
	Format(g_strCampaignName[15], 32, "Heaven Can Wait II");
	Format(g_strCampaignName[16], 32, "I Hate Mountains 2 (1.5)");
	Format(g_strCampaignName[17], 32, "One 4 Nine");
	Format(g_strCampaignName[18], 32, "Diescraper Redux 3.5");
	Format(g_strCampaignName[19], 32, "Left 4 Mario");
	Format(g_strCampaignName[20], 32, "Ft. Noesis L4D2");
	Format(g_strCampaignName[21], 32, "Overkill");
	Format(g_strCampaignName[22], 32, "Precinct 84");
	Format(g_strCampaignName[23], 32, "Questionable Ethics");
	Format(g_strCampaignName[24], 32, "We Don't Go To Ravenholm 2");
	Format(g_strCampaignName[25], 32, "Urban Flight");
	Format(g_strCampaignName[26], 32, "Vienna Calling");
	Format(g_strCampaignName[27], 32, "Vienna Calling 2");
	Format(g_strCampaignName[28], 32, "2 Evil Eyes");
	Format(g_strCampaignName[29], 32, "Dead Vacation L4D2");
	Format(g_strCampaignName[30], 32, "Death Stop L4D2");
	Format(g_strCampaignName[31], 32, "drop dead gorges v2.1");
	Format(g_strCampaignName[32], 32, "Deadbeat Escape");
	Format(g_strCampaignName[33], 32, "Gas Fever");
	Format(g_strCampaignName[34], 32, "GoldenEye");
	Format(g_strCampaignName[35], 32, "Yama");
	Format(g_strCampaignName[36], 32, "You Are Doomed L4D2");
	Format(g_strCampaignName[37], 32, "Run To The Hills");
	Format(g_strCampaignName[38], 32, "25 To Life");
	Format(g_strCampaignName[39], 32, "Dark Blood 2");
	Format(g_strCampaignName[40], 32, "Fall In Death");
	Format(g_strCampaignName[41], 32, "Death Strip");
	Format(g_strCampaignName[42], 32, "Zombie Movie Without Name!");
	Format(g_strCampaignName[43], 32, "Cape Murder 2");
	Format(g_strCampaignName[44], 32, "Strandead 2");
	Format(g_strCampaignName[45], 32, "Blackout Basement");
	Format(g_strCampaignName[46], 32, "The Dark Parish");
	Format(g_strCampaignName[47], 32, "Dead Before Dawn Too");
	Format(g_strCampaignName[48], 32, "Die Screaming II");
	Format(g_strCampaignName[49], 32, "Welcome To Hell");
	Format(g_strCampaignName[50], 32, "Source of Infection Timelords Ver");
	Format(g_strCampaignName[51], 32, "The Cure");
	Format(g_strCampaignName[52], 32, "Open Road");
	Format(g_strCampaignName[53], 32, "No Space 4 Zombies");
	Format(g_strCampaignName[54], 32, "Pasiri");
	Format(g_strCampaignName[55], 32, "Carried Off");
	Format(g_strCampaignName[56], 32, "Beldurra");
	Format(g_strCampaignName[57], 32, "Blood Proof");
	Format(g_strCampaignName[58], 32, "Powerstation 2");
	Format(g_strCampaignName[59], 32, "Stenches");
	Format(g_strCampaignName[60], 32, "The Undead Zone");
	Format(g_strCampaignName[61], 32, "A Dam Mission");
	Format(g_strCampaignName[62], 32, "Left Behind");
	Format(g_strCampaignName[63], 32, "Blight Path");
	Format(g_strCampaignName[64], 32, "Free Passage");
	Format(g_strCampaignName[65], 32, "Unreal Tournament");
	Format(g_strCampaignName[66], 32, "Lost v2 Fixed");
	Format(g_strCampaignName[67], 32, "Lambda L4D2");
	Format(g_strCampaignName[68], 32, "Salt Hell Park");
	Format(g_strCampaignName[69], 32, "DeadSeries");
	Format(g_strCampaignName[70], 32, "Dead Echo 2");
	Format(g_strCampaignName[71], 32, "7 Hours Later");
	Format(g_strCampaignName[72], 32, "Dead Center");
	Format(g_strCampaignName[73], 32, "Dark Carnival");
	Format(g_strCampaignName[74], 32, "Swamp Fever");
	Format(g_strCampaignName[75], 32, "Hard Rain");
	Format(g_strCampaignName[76], 32, "The Parish");
	Format(g_strCampaignName[77], 32, "The Passing");
	Format(g_strCampaignName[78], 32, "The Sacrifice");
	Format(g_strCampaignName[79], 32, "No Mercy");
	Format(g_strCampaignName[80], 32, "Crash Course");
	Format(g_strCampaignName[81], 32, "Death Toll");
	Format(g_strCampaignName[82], 32, "Dead Air");
	Format(g_strCampaignName[83], 32, "Blood Harvest");
	Format(g_strCampaignName[84], 32, "Cold Stream");
	Format(g_strCampaignName[85], 32, "Downtown Dine");
	Format(g_strCampaignName[86], 32, "Death Woods");
	Format(g_strCampaignName[87], 32, "Grey Scale");
	Format(g_strCampaignName[88], 32, "Going Ballistic");
	Format(g_strCampaignName[89], 32, "Highway To Hell");
	Format(g_strCampaignName[90], 32, "Surrounded By The Dead II");
	Format(g_strCampaignName[91], 32, "Cold Case: The Forsaken");
	Format(g_strCampaignName[92], 32, "Centro");
	Format(g_strCampaignName[93], 32, "Tour Of Terror");
	Format(g_strCampaignName[94], 32, "Arena Of The Dead 2 v5");
	Format(g_strCampaignName[95], 32, "Gone In 60 Smokers v3");
	Format(g_strCampaignName[96], 32, "Space Jockeys");
	Format(g_strCampaignName[97], 32, "Wormwood");
	Format(g_strCampaignName[98], 32, "Titty Twister");
	Format(g_strCampaignName[99], 32, "Indiana Jones and the Temple of Zombies");
	Format(g_strCampaignName[100], 32, "Dead Industry 2");
	Format(g_strCampaignName[101], 32, "No More Industries 2");
	Format(g_strCampaignName[102], 32, "Urban Disaster (0.90)");
	Format(g_strCampaignName[103], 32, "DeadCity II");
	Format(g_strCampaignName[104], 32, "Die Screaming II");
	Format(g_strCampaignName[105], 32, "Clamtoll: L4D2 Death Toll Remake");
	Format(g_strCampaignName[106], 32, "Death Mountain");
	Format(g_strCampaignName[107], 32, "The Last Volt");
	Format(g_strCampaignName[108], 32, "No Mercy APOCALYPSE 2");
	Format(g_strCampaignName[109], 32, "Death Toll APOCALYPSE 2");
	Format(g_strCampaignName[110], 32, "Blood Harvest APOCALYPSE 2");
	Format(g_strCampaignName[111], 32, "Crash Course APOCALYPSE 2");
	Format(g_strCampaignName[112], 32, "Blood Woods APOCALYPSE 2");
	Format(g_strCampaignName[113], 32, "Pitch Dark Mesa");
	Format(g_strCampaignName[114], 32, "No Way Out");
	Format(g_strCampaignName[115], 32, "Lost In Linz 2");
	Format(g_strCampaignName[116], 32, "Dniepr");
	Format(g_strCampaignName[117], 32, "The Bloody Moors");
	Format(g_strCampaignName[118], 32, "Infected City");
	Format(g_strCampaignName[119], 32, "Infected City II");
	Format(g_strCampaignName[120], 32, "Perfect Hideout 2");
	Format(g_strCampaignName[121], 32, "ZMB-13");
	Format(g_strCampaignName[122], 32, "Taco Bucket");
	Format(g_strCampaignName[123], 32, "Surrounded By The Dead II");
	Format(g_strCampaignName[124], 32, "Death Row");
	Format(g_strCampaignName[125], 32, "Last Call");
	Format(g_strCampaignName[126], 32, "Disturbed In The Suburbs");
	Format(g_strCampaignName[127], 32, "Dead Military 2");
	Format(g_strCampaignName[128], 32, "Cold Case");
	Format(g_strCampaignName[129], 32, "Die Screaming II");
	Format(g_strCampaignName[130], 32, "Quedan 4X Morir L4D2");
	Format(g_strCampaignName[131], 32, "Dead Getaway L4D2");
	Format(g_strCampaignName[132], 32, "No Way Out 2");
	Format(g_strCampaignName[133], 32, "TBM Survivor");
	Format(g_strCampaignName[134], 32, "RMS Titanic");
	Format(g_strCampaignName[135], 32, "Midnight Rail Run");
	Format(g_strCampaignName[136], 32, "Absolute Zero");
	Format(g_strCampaignName[137], 32, "Burning Down Under");
	Format(g_strCampaignName[138], 32, "Blood Hospital 2");
	Format(g_strCampaignName[139], 32, "Blood Harvest Modified (2.7)");
	Format(g_strCampaignName[140], 32, "Bloody Sunday 2");
	Format(g_strCampaignName[141], 32, "Carnage 2");
	Format(g_strCampaignName[142], 32, "Claustrophobia");
	Format(g_strCampaignName[143], 32, "Cold Fear L4D2");
	Format(g_strCampaignName[144], 32, "Dead Street 2 (2.0)");
	Format(g_strCampaignName[145], 32, "Dead Street 13");
	Format(g_strCampaignName[146], 32, "Dead High School 2.0");
	Format(g_strCampaignName[147], 32, "Left 4 Bowl");
	Format(g_strCampaignName[148], 32, "Napalm Death");
	Format(g_strCampaignName[149], 32, "Die Trying 2");
	Format(g_strCampaignName[150], 32, "Mars Base Alpha");
	Format(g_strCampaignName[151], 32, "Prototype Mk3");
	Format(g_strCampaignName[152], 32, "Dead Flag Blues 2");
	Format(g_strCampaignName[153], 32, "Shadow Moses Island");
	Format(g_strCampaignName[154], 32, "Left 4 Duluth");
	Format(g_strCampaignName[155], 32, "Coal'd Blood 2");
	Format(g_strCampaignName[156], 32, "China of the dead(beta)");
	Format(g_strCampaignName[157], 32, "Crescendo Collision");
	Format(g_strCampaignName[158], 32, "Deathcraft 2.1");
	Format(g_strCampaignName[159], 32, "Escape From Toronto");
	Format(g_strCampaignName[160], 32, "RoadToNowhere II");
	Format(g_strCampaignName[161], 32, "$DetourAhead_Title");
	Format(g_strCampaignName[162], 32, "Crash Course Modified v5.0");
	Format(g_strCampaignName[163], 32, "Ruination");
	Format(g_strCampaignName[164], 32, "GoldenEye 4 Dead");
	Format(g_strCampaignName[165], 32, "Kruffty Center");
	Format(g_strCampaignName[166], 32, "Dead Destination");
	Format(g_strCampaignName[167], 32, "death Sentence");
	Format(g_strCampaignName[168], 32, "Bad Neighborhood");
	Format(g_strCampaignName[169], 32, "Deadly Ending");
	Format(g_strCampaignName[170], 32, "Dead Run L4D2");
	Format(g_strCampaignName[171], 32, "Vague Reminders");
	Format(g_strCampaignName[172], 32, "Echo Evac");
	Format(g_strCampaignName[173], 32, "Hard Rain: Downpour");
	Format(g_strCampaignName[174], 32, "The Hive");
	Format(g_strCampaignName[175], 32, "Ottawa Rock City");
	Format(g_strCampaignName[176], 32, "Racoon City Nemesis");
	Format(g_strCampaignName[177], 32, "Heartbreak Fridge");
	Format(g_strCampaignName[178], 32, "Military Industrial Complex II V11");
	Format(g_strCampaignName[179], 32, "Kink");
	Format(g_strCampaignName[180], 32, "Dark Wood");
	Format(g_strCampaignName[181], 32, "Journey to Splash Mountain");
	Format(g_strCampaignName[182], 32, "Convoy");
	Format(g_strCampaignName[183], 32, "Fatal Freight");
	Format(g_strCampaignName[184], 32, "Stargate SG-4 v2");
	Format(g_strCampaignName[185], 32, "Escape from Malabar v7");
	Format(g_strCampaignName[186], 32, "The Bitter End");
	Format(g_strCampaignName[187], 32, "Dead End");
	Format(g_strCampaignName[188], 32, "Dead Industry 2");
	Format(g_strCampaignName[189], 32, "Roadkill");
	Format(g_strCampaignName[190], 32, "Crossing Over 2");
	Format(g_strCampaignName[191], 32, "Resident Evil Outbreak");
	Format(g_strCampaignName[192], 32, "Day Break");
	Format(g_strCampaignName[193], 32, "Energy Crisis");
	Format(g_strCampaignName[194], 32, "Naniwa City 2");
	Format(g_strCampaignName[195], 32, "Dead On Time L4D2");
	Format(g_strCampaignName[196], 32, "Hellish Journey");
	Format(g_strCampaignName[197], 32, "Derailed 2");
	Format(g_strCampaignName[198], 32, "Death Island");
	Format(g_strCampaignName[199], 32, "Black City: Silent Hill");
	Format(g_strCampaignName[200], 32, "Cursed and Babbling TLM Ver");
	Format(g_strCampaignName[201], 32, "Dead Series Original");
	Format(g_strCampaignName[202], 32, "Project Auburn L4D1");
	Format(g_strCampaignName[203], 32, "The Return: The Sequel");
	Format(g_strCampaignName[204], 32, "Left or Right Beta");
	Format(g_strCampaignName[205], 32, "Left or Right Beta");
	Format(g_strCampaignName[206], 32, "Left or Right Beta");
	Format(g_strCampaignName[207], 32, "Project Auburn 2");
	
	//The following string variables are only for Scavenge
	
	//*IMPORTANT* Before editing these change NUMBER_OF_SCAVENGE_MAPS 
	//near the top of this plugin to match the total number of scavenge  
	//maps, or it will not loop through all of them when changing maps.
	
	//Scavenge Maps
	Format(g_strScavengeMap[0], 32, "c8m1_apartment");
	Format(g_strScavengeMap[1], 32, "c8m5_rooftop");
	Format(g_strScavengeMap[2], 32, "c1m4_atrium");
	Format(g_strScavengeMap[3], 32, "c7m1_docks");
	Format(g_strScavengeMap[4], 32, "c7m2_barge");
	Format(g_strScavengeMap[5], 32, "c6m1_riverbank");
	Format(g_strScavengeMap[6], 32, "c6m2_bedlam");
	Format(g_strScavengeMap[7], 32, "c6m3_port");
	Format(g_strScavengeMap[8], 32, "c2m1_highway");
	Format(g_strScavengeMap[9], 32, "c3m1_plankcountry");
	Format(g_strScavengeMap[10], 32, "c4m1_milltown_a");
	Format(g_strScavengeMap[11], 32, "c4m2_sugarmill_a");
	Format(g_strScavengeMap[12], 32, "c5m2_park");
	
	//Scavenge Map Names
	Format(g_strScavengeMapName[0], 32, "Apartments");
	Format(g_strScavengeMapName[1], 32, "Rooftop");
	Format(g_strScavengeMapName[2], 32, "Mall Atrium");
	Format(g_strScavengeMapName[3], 32, "Brick Factory");
	Format(g_strScavengeMapName[4], 32, "Barge");
	Format(g_strScavengeMapName[5], 32, "Riverbank");
	Format(g_strScavengeMapName[6], 32, "Underground");
	Format(g_strScavengeMapName[7], 32, "Port");
	Format(g_strScavengeMapName[8], 32, "Motel");
	Format(g_strScavengeMapName[9], 32, "Plank Country");
	Format(g_strScavengeMapName[10], 32, "Milltown");
	Format(g_strScavengeMapName[11], 32, "Sugar Mill");
	Format(g_strScavengeMapName[12], 32, "Park");
}


/*======================================================================================
#################             O N   P L U G I N   S T A R T            #################
======================================================================================*/

public OnPluginStart()
{
	//Get the strings for all of the maps that are in rotation
	SetupMapStrings();
	
	//Create custom console variables
	CreateConVar("acs_version", PLUGIN_VERSION, "Version of Automatic Campaign Switcher (ACS) on this server", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hCVar_VotingEnabled = CreateConVar("acs_voting_system_enabled", "1", "Enables players to vote for the next map or campaign [0 = DISABLED, 1 = ENABLED]", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCVar_VoteWinnerSoundEnabled = CreateConVar("acs_voting_sound_enabled", "1", "Determines if a sound plays when a new map is winning the vote [0 = DISABLED, 1 = ENABLED]", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCVar_VotingAdMode = CreateConVar("acs_voting_ad_mode", "1", "Sets how to advertise voting at the start of the map [0 = DISABLED, 1 = HINT TEXT, 2 = CHAT TEXT, 3 = OPEN VOTE MENU]\n * Note: This is only displayed once during a finale or scavenge map *", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	g_hCVar_VotingAdDelayTime = CreateConVar("acs_voting_ad_delay_time", "5.0", "Time, in seconds, to wait after survivors leave the start area to advertise voting as defined in acs_voting_ad_mode\n * Note: If the server is up, changing this in the .cfg file takes two map changes before the change takes place *", FCVAR_PLUGIN, true, 0.1, false);
	g_hCVar_NextMapAdMode = CreateConVar("acs_next_map_ad_mode", "1", "Sets how the next campaign/map is advertised during a finale or scavenge map [0 = DISABLED, 1 = HINT TEXT, 2 = CHAT TEXT]", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	g_hCVar_NextMapAdInterval = CreateConVar("acs_next_map_ad_interval", "600.0", "The time, in seconds, between advertisements for the next campaign/map on finales and scavenge maps", FCVAR_PLUGIN, true, 60.0, false);
	g_hCVar_MaxFinaleFailures = CreateConVar("acs_max_coop_finale_failures", "0", "The amount of times the survivors can fail a finale in Coop before it switches to the next campaign [0 = INFINITE FAILURES]", FCVAR_PLUGIN, true, 0.0, false);
	
	//Hook console variable changes
	HookConVarChange(g_hCVar_VotingEnabled, CVarChange_Voting);
	HookConVarChange(g_hCVar_VoteWinnerSoundEnabled, CVarChange_NewVoteWinnerSound);
	HookConVarChange(g_hCVar_VotingAdMode, CVarChange_VotingAdMode);
	HookConVarChange(g_hCVar_VotingAdDelayTime, CVarChange_VotingAdDelayTime);
	HookConVarChange(g_hCVar_NextMapAdMode, CVarChange_NewMapAdMode);
	HookConVarChange(g_hCVar_NextMapAdInterval, CVarChange_NewMapAdInterval);
	HookConVarChange(g_hCVar_MaxFinaleFailures, CVarChange_MaxFinaleFailures);
		
	//Hook the game events
	//HookEvent("round_start", Event_RoundStart);
	//HookEvent("player_left_start_area", Event_PlayerLeftStartArea);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("finale_win", Event_FinaleWin);
	HookEvent("scavenge_match_finished", Event_ScavengeMapFinished);
	HookEvent("player_disconnect", Event_PlayerDisconnect);
	
	//Register custom console commands
	RegConsoleCmd("mapvote", MapVote);
	RegConsoleCmd("mapvotes", DisplayCurrentVotes);
}

/*======================================================================================
##########           C V A R   C A L L B A C K   F U N C T I O N S           ###########
======================================================================================*/

//Callback function for the cvar for voting system
public CVarChange_Voting(Handle:hCVar, const String:strOldValue[], const String:strNewValue[])
{
	//If the value was not changed, then do nothing
	if(StrEqual(strOldValue, strNewValue) == true)
		return;
	
	//If the value was changed, then set it and display a message to the server and players
	if (StringToInt(strNewValue) == 1)
	{
		g_bVotingEnabled = true;
		PrintToServer("[ACS] ConVar changed: Voting System ENABLED");
		PrintToChatAll("[ACS] ConVar changed: Voting System ENABLED");
	}
	else
	{
		g_bVotingEnabled = false;
		PrintToServer("[ACS] ConVar changed: Voting System DISABLED");
		PrintToChatAll("[ACS] ConVar changed: Voting System DISABLED");
	}
}

//Callback function for enabling or disabling the new vote winner sound
public CVarChange_NewVoteWinnerSound(Handle:hCVar, const String:strOldValue[], const String:strNewValue[])
{
	//If the value was not changed, then do nothing
	if(StrEqual(strOldValue, strNewValue) == true)
		return;
	
	//If the value was changed, then set it and display a message to the server and players
	if (StringToInt(strNewValue) == 1)
	{
		g_bVoteWinnerSoundEnabled = true;
		PrintToServer("[ACS] ConVar changed: New vote winner sound ENABLED");
		PrintToChatAll("[ACS] ConVar changed: New vote winner sound ENABLED");
	}
	else
	{
		g_bVoteWinnerSoundEnabled = false;
		PrintToServer("[ACS] ConVar changed: New vote winner sound DISABLED");
		PrintToChatAll("[ACS] ConVar changed: New vote winner sound DISABLED");
	}
}

//Callback function for how the voting system is advertised to the players at the beginning of the round
public CVarChange_VotingAdMode(Handle:hCVar, const String:strOldValue[], const String:strNewValue[])
{
	//If the value was not changed, then do nothing
	if(StrEqual(strOldValue, strNewValue) == true)
		return;
	
	//If the value was changed, then set it and display a message to the server and players
	switch(StringToInt(strNewValue))
	{
		case 0:
		{
			g_iVotingAdDisplayMode = DISPLAY_MODE_DISABLED;
			PrintToServer("[ACS] ConVar changed: Voting display mode: DISABLED");
			PrintToChatAll("[ACS] ConVar changed: Voting display mode: DISABLED");
		}
		case 1:
		{
			g_iVotingAdDisplayMode = DISPLAY_MODE_HINT;
			PrintToServer("[ACS] ConVar changed: Voting display mode: HINT TEXT");
			PrintToChatAll("[ACS] ConVar changed: Voting display mode: HINT TEXT");
		}
		case 2:
		{
			g_iVotingAdDisplayMode = DISPLAY_MODE_CHAT;
			PrintToServer("[ACS] ConVar changed: Voting display mode: CHAT TEXT");
			PrintToChatAll("[ACS] ConVar changed: Voting display mode: CHAT TEXT");
		}
		case 3:
		{
			g_iVotingAdDisplayMode = DISPLAY_MODE_MENU;
			PrintToServer("[ACS] ConVar changed: Voting display mode: OPEN VOTE MENU");
			PrintToChatAll("[ACS] ConVar changed: Voting display mode: OPEN VOTE MENU");
		}
	}
}

//Callback function for the cvar for voting display delay time
public CVarChange_VotingAdDelayTime(Handle:hCVar, const String:strOldValue[], const String:strNewValue[])
{
	//If the value was not changed, then do nothing
	if(StrEqual(strOldValue, strNewValue) == true)
		return;
	
	//Get the new value
	new Float:fDelayTime = StringToFloat(strNewValue);
	
	//If the value was changed, then set it and display a message to the server and players
	if (fDelayTime > 0.1)
	{
		g_fVotingAdDelayTime = fDelayTime;
		PrintToServer("[ACS] ConVar changed: Voting advertisement delay time changed to %f", fDelayTime);
		PrintToChatAll("[ACS] ConVar changed: Voting advertisement delay time changed to %f", fDelayTime);
	}
	else
	{
		g_fVotingAdDelayTime = 0.1;
		PrintToServer("[ACS] ConVar changed: Voting advertisement delay time changed to 0.1");
		PrintToChatAll("[ACS] ConVar changed: Voting advertisement delay time changed to 0.1");
	}
}

//Callback function for how ACS and the next map is advertised to the players during a finale
public CVarChange_NewMapAdMode(Handle:hCVar, const String:strOldValue[], const String:strNewValue[])
{
	//If the value was not changed, then do nothing
	if(StrEqual(strOldValue, strNewValue) == true)
		return;
	
	//If the value was changed, then set it and display a message to the server and players
	switch(StringToInt(strNewValue))
	{
		case 0:
		{
			g_iNextMapAdDisplayMode = DISPLAY_MODE_DISABLED;
			PrintToServer("[ACS] ConVar changed: Next map advertisement display mode: DISABLED");
			PrintToChatAll("[ACS] ConVar changed: Next map advertisement display mode: DISABLED");
		}
		case 1:
		{
			g_iNextMapAdDisplayMode = DISPLAY_MODE_HINT;
			PrintToServer("[ACS] ConVar changed: Next map advertisement display mode: HINT TEXT");
			PrintToChatAll("[ACS] ConVar changed: Next map advertisement display mode: HINT TEXT");
		}
		case 2:
		{
			g_iNextMapAdDisplayMode = DISPLAY_MODE_CHAT;
			PrintToServer("[ACS] ConVar changed: Next map advertisement display mode: CHAT TEXT");
			PrintToChatAll("[ACS] ConVar changed: Next map advertisement display mode: CHAT TEXT");
		}
	}
}

//Callback function for the interval that controls the timer that advertises ACS and the next map
public CVarChange_NewMapAdInterval(Handle:hCVar, const String:strOldValue[], const String:strNewValue[])
{
	//If the value was not changed, then do nothing
	if(StrEqual(strOldValue, strNewValue) == true)
		return;
	
	//Get the new value
	new Float:fDelayTime = StringToFloat(strNewValue);
	
	//If the value was changed, then set it and display a message to the server and players
	if (fDelayTime > 60.0)
	{
		g_fNextMapAdInterval = fDelayTime;
		PrintToServer("[ACS] ConVar changed: Next map advertisement interval changed to %f", fDelayTime);
		PrintToChatAll("[ACS] ConVar changed: Next map advertisement interval changed to %f", fDelayTime);
	}
	else
	{
		g_fNextMapAdInterval = 60.0;
		PrintToServer("[ACS] ConVar changed: Next map advertisement interval changed to 60.0");
		PrintToChatAll("[ACS] ConVar changed: Next map advertisement interval changed to 60.0");
	}
}

//Callback function for the amount of times the survivors can fail a coop finale map before ACS switches
public CVarChange_MaxFinaleFailures(Handle:hCVar, const String:strOldValue[], const String:strNewValue[])
{
	//If the value was not changed, then do nothing
	if(StrEqual(strOldValue, strNewValue) == true)
		return;
	
	//Get the new value
	new iMaxFailures = StringToInt(strNewValue);
	
	//If the value was changed, then set it and display a message to the server and players
	if (iMaxFailures > 0)
	{
		g_iMaxCoopFinaleFailures = iMaxFailures;
		PrintToServer("[ACS] ConVar changed: Max Coop finale failures changed to %f", iMaxFailures);
		PrintToChatAll("[ACS] ConVar changed: Max Coop finale failures changed to %f", iMaxFailures);
	}
	else
	{
		g_iMaxCoopFinaleFailures = 0;
		PrintToServer("[ACS] ConVar changed: Max Coop finale failures changed to 0");
		PrintToChatAll("[ACS] ConVar changed: Max Coop finale failures changed to 0");
	}
}
/*======================================================================================
#################                     E V E N T S                      #################
======================================================================================*/

public OnMapStart()
{
	//Execute config file
	decl String:strFileName[64];
	Format(strFileName, sizeof(strFileName), "Automatic_Campaign_Switcher_%s", PLUGIN_VERSION);
	AutoExecConfig(true, strFileName);
	
	//Set all the menu handles to invalid
	CleanUpMenuHandles();
	
	//Set the game mode
	FindGameMode();
	
	//Precache sounds
	PrecacheSound(SOUND_NEW_VOTE_START);
	PrecacheSound(SOUND_NEW_VOTE_WINNER);
	
	
	//Display advertising for the next campaign or map
	if(g_iNextMapAdDisplayMode != DISPLAY_MODE_DISABLED)
		CreateTimer(g_fNextMapAdInterval, Timer_AdvertiseNextMap, _, TIMER_FLAG_NO_MAPCHANGE);
	
	g_iRoundEndCounter = 0;			//Reset the round end counter on every map start
	g_iCoopFinaleFailureCount = 0;	//Reset the amount of Survivor failures
	g_bFinaleWon = false;			//Reset the finale won variable
	ResetAllVotes();				//Reset every player's vote
}

//Event fired when a player is fully in game
public OnClientPostAdminCheck(iClient)
{
	if(IsClientInGame(iClient) && !IsFakeClient(iClient))
	{
		if(g_bVotingEnabled == true && OnFinaleOrScavengeMap() == true)
			CreateTimer(g_fVotingAdDelayTime, Timer_DisplayVoteAdToAll, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

//Event fired when the Round Ends
public Action:Event_RoundEnd(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{
	//Check to see if on a finale map, if so change to the next campaign after two rounds
	if(g_iGameMode == GAMEMODE_VERSUS && OnFinaleOrScavengeMap() == true)
	{
		g_iRoundEndCounter++;
		
		if(g_iRoundEndCounter >= 4)	//This event must be fired on the fourth time Round End occurs.
			CheckMapForChange();	//This is because it fires twice during each round end for
									//some strange reason, and versus has two rounds in it.
	}
	//If in Coop and on a finale, check to see if the surviors have lost the max amount of times
	else if(g_iGameMode == GAMEMODE_COOP && OnFinaleOrScavengeMap() == true &&
			g_iMaxCoopFinaleFailures > 0 && g_bFinaleWon == false &&
			++g_iCoopFinaleFailureCount >= g_iMaxCoopFinaleFailures)
	{
		CheckMapForChange();
	}
	
	return Plugin_Continue;
}

//Event fired when a finale is won
public Action:Event_FinaleWin(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{
	g_bFinaleWon = true;	//This is used so that the finale does not switch twice if this event
							//happens to land on a max failure count as well as this
	
	//Change to the next campaign
	if(g_iGameMode == GAMEMODE_COOP)
		CheckMapForChange();
	
	return Plugin_Continue;
}

//Event fired when a map is finished for scavenge
public Action:Event_ScavengeMapFinished(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{
	//Change to the next Scavenge map
	if(g_iGameMode == GAMEMODE_SCAVENGE)
		ChangeScavengeMap();
	
	return Plugin_Continue;
}

//Event fired when a player disconnects from the server
public Action:Event_PlayerDisconnect(Handle:hEvent, const String:strName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(iClient	< 1)
		return Plugin_Continue;
	
	//Reset the client's votes
	g_bClientVoted[iClient] = false;
	g_iClientVote[iClient] = -1;
	
	//Check to see if there is a new vote winner
	SetTheCurrentVoteWinner();
	
	return Plugin_Continue;
}

/*======================================================================================
#################              F I N D   G A M E   M O D E             #################
======================================================================================*/

//Find the current gamemode and store it into this plugin
FindGameMode()
{
	//Get the gamemode string from the game
	decl String:strGameMode[20];
	GetConVarString(FindConVar("mp_gamemode"), strGameMode, sizeof(strGameMode));
	
	//Set the global gamemode int for this plugin
	if(StrEqual(strGameMode, "coop"))
		g_iGameMode = GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "realism"))
		g_iGameMode = GAMEMODE_COOP;
	else if(StrEqual(strGameMode,"versus"))
		g_iGameMode = GAMEMODE_VERSUS;
	else if(StrEqual(strGameMode, "teamversus"))
		g_iGameMode = GAMEMODE_VERSUS;
	else if(StrEqual(strGameMode, "scavenge"))
		g_iGameMode = GAMEMODE_SCAVENGE;
	else if(StrEqual(strGameMode, "teamscavenge"))
		g_iGameMode = GAMEMODE_SCAVENGE;
	else if(StrEqual(strGameMode, "survival"))
		g_iGameMode = GAMEMODE_SURVIVAL;
	else if(StrEqual(strGameMode, "mutation1"))		//Last Man On Earth
		g_iGameMode = GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation2"))		//Headshot!
		g_iGameMode = GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation3"))		//Bleed Out
		g_iGameMode = GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation4"))		//Hard Eight
		g_iGameMode = GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation5"))		//Four Swordsmen
		g_iGameMode = GAMEMODE_COOP;
	//else if(StrEqual(strGameMode, "mutation6"))	//Nothing here
	//	g_iGameMode = GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation7"))		//Chainsaw Massacre
		g_iGameMode = GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation8"))		//Ironman
		g_iGameMode = GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation9"))		//Last Gnome On Earth
		g_iGameMode = GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation10"))	//Room For One
		g_iGameMode = GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation11"))	//Healthpackalypse!
		g_iGameMode = GAMEMODE_VERSUS;
	else if(StrEqual(strGameMode, "mutation12"))	//Realism Versus
		g_iGameMode = GAMEMODE_VERSUS;
	else if(StrEqual(strGameMode, "mutation13"))	//Follow the Liter
		g_iGameMode = GAMEMODE_SCAVENGE;
	else if(StrEqual(strGameMode, "mutation14"))	//Gib Fest
		g_iGameMode = GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation15"))	//Versus Survival
		g_iGameMode = GAMEMODE_SURVIVAL;
	else if(StrEqual(strGameMode, "mutation16"))	//Hunting Party
		g_iGameMode = GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation17"))	//Lone Gunman
		g_iGameMode = GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "mutation18"))	//Bleed Out Versus
		g_iGameMode = GAMEMODE_VERSUS;
	else if(StrEqual(strGameMode, "mutation19"))	//Taaannnkk!
		g_iGameMode = GAMEMODE_VERSUS;
	else if(StrEqual(strGameMode, "mutation20"))	//Healing Gnome
		g_iGameMode = GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "community1"))	//Special Delivery
		g_iGameMode = GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "community2"))	//Flu Season
		g_iGameMode = GAMEMODE_COOP;
	else if(StrEqual(strGameMode, "community3"))	//Riding My Survivor
		g_iGameMode = GAMEMODE_VERSUS;
	else if(StrEqual(strGameMode, "community4"))	//Nightmare
		g_iGameMode = GAMEMODE_SURVIVAL;
	else if(StrEqual(strGameMode, "community5"))	//Death's Door
		g_iGameMode = GAMEMODE_COOP;
	else
		g_iGameMode = GAMEMODE_UNKNOWN;
}

/*======================================================================================
#################             A C S   C H A N G E   M A P              #################
======================================================================================*/

//Check to see if the current map is a finale, and if so, switch to the next campaign
CheckMapForChange()
{
	decl String:strCurrentMap[32];
	GetCurrentMap(strCurrentMap,32);					//Get the current map from the game
	
	for(new iMapIndex = 0; iMapIndex < NUMBER_OF_CAMPAIGNS; iMapIndex++)
	{
		if(StrEqual(strCurrentMap, g_strCampaignLastMap[iMapIndex]) == true)
		{
			//Check to see if someone voted for a campaign, if so, then change to the winning campaign
			if(g_bVotingEnabled == true && g_iWinningMapVotes > 0 && g_iWinningMapIndex >= 0)
			{
				if(IsMapValid(g_strCampaignFirstMap[g_iWinningMapIndex]) == true)
				{
					PrintToChatAll("\x04[ACS] \x03Switching campaign to the vote winner: \x04%s", g_strCampaignName[g_iWinningMapIndex]);
					
					if(g_iGameMode == GAMEMODE_VERSUS)
						CreateTimer(WAIT_TIME_BEFORE_SWITCH_VERSUS, Timer_ChangeCampaign, g_iWinningMapIndex);
					else if(g_iGameMode == GAMEMODE_COOP)
						CreateTimer(WAIT_TIME_BEFORE_SWITCH_COOP, Timer_ChangeCampaign, g_iWinningMapIndex);
					
					return;
				}
				else
					LogError("Error: %s is an invalid map name, attempting normal map rotation.", g_strCampaignFirstMap[g_iWinningMapIndex]);
			}
			
			//If no map was chosen in the vote, then go with the automatic map rotation
			
			if(iMapIndex == NUMBER_OF_CAMPAIGNS - 1)	//Check to see if its the end of the array
				iMapIndex = -1;							//If so, start the array over by setting to -1 + 1 = 0
				
			if(IsMapValid(g_strCampaignFirstMap[iMapIndex + 1]) == true)
			{
				PrintToChatAll("\x04[ACS] \x03Switching campaign to \x04%s", g_strCampaignName[iMapIndex + 1]);
				
				if(g_iGameMode == GAMEMODE_VERSUS)
					CreateTimer(WAIT_TIME_BEFORE_SWITCH_VERSUS, Timer_ChangeCampaign, iMapIndex + 1);
				else if(g_iGameMode == GAMEMODE_COOP)
					CreateTimer(WAIT_TIME_BEFORE_SWITCH_COOP, Timer_ChangeCampaign, iMapIndex + 1);
			}
			else
				LogError("Error: %s is an invalid map name, unable to switch map.", g_strCampaignFirstMap[iMapIndex + 1]);
			
			return;
		}
	}
}

//Change to the next scavenge map
ChangeScavengeMap()
{
	//Check to see if someone voted for a map, if so, then change to the winning map
	if(g_bVotingEnabled == true && g_iWinningMapVotes > 0 && g_iWinningMapIndex >= 0)
	{
		if(IsMapValid(g_strScavengeMap[g_iWinningMapIndex]) == true)
		{
			PrintToChatAll("\x04[ACS] \x03Switching map to the vote winner: \x04%s", g_strScavengeMapName[g_iWinningMapIndex]);
			
			CreateTimer(WAIT_TIME_BEFORE_SWITCH_SCAVENGE, Timer_ChangeScavengeMap, g_iWinningMapIndex);
			
			return;
		}
		else
			LogError("Error: %s is an invalid map name, attempting normal map rotation.", g_strScavengeMap[g_iWinningMapIndex]);
	}
	
	//If no map was chosen in the vote, then go with the automatic map rotation
	
	decl String:strCurrentMap[32];
	GetCurrentMap(strCurrentMap, 32);					//Get the current map from the game
	
	//Go through all maps and to find which map index it is on, and then switch to the next map
	for(new iMapIndex = 0; iMapIndex < NUMBER_OF_SCAVENGE_MAPS; iMapIndex++)
	{
		if(StrEqual(strCurrentMap, g_strScavengeMap[iMapIndex]) == true)
		{
			if(iMapIndex == NUMBER_OF_SCAVENGE_MAPS - 1)//Check to see if its the end of the array
				iMapIndex = -1;							//If so, start the array over by setting to -1 + 1 = 0 
			
			//Make sure the map is valid before changing and displaying the message
			if(IsMapValid(g_strScavengeMap[iMapIndex + 1]) == true)
			{
				PrintToChatAll("\x04[ACS] \x03Switching map to \x04%s", g_strScavengeMapName[iMapIndex + 1]);
				
				CreateTimer(WAIT_TIME_BEFORE_SWITCH_SCAVENGE, Timer_ChangeScavengeMap, iMapIndex + 1);
			}
			else
				LogError("Error: %s is an invalid map name, unable to switch map.", g_strScavengeMap[iMapIndex + 1]);
			
			return;
		}
	}
}

//Change campaign to its index
public Action:Timer_ChangeCampaign(Handle:timer, any:iCampaignIndex)
{
	ServerCommand("changelevel %s", g_strCampaignFirstMap[iCampaignIndex]);	//Change the campaign
	
	return Plugin_Stop;
}

//Change scavenge map to its index
public Action:Timer_ChangeScavengeMap(Handle:timer, any:iMapIndex)
{
	ServerCommand("changelevel %s", g_strScavengeMap[iMapIndex]);			//Change the map
	
	return Plugin_Stop;
}

/*======================================================================================
#################            A C S   A D V E R T I S I N G             #################
======================================================================================*/

public Action:Timer_AdvertiseNextMap(Handle:timer, any:iMapIndex)
{
	//If next map advertising is enabled, display the text and start the timer again
	if(g_iNextMapAdDisplayMode != DISPLAY_MODE_DISABLED)
	{
		DisplayNextMapToAll();
		CreateTimer(g_fNextMapAdInterval, Timer_AdvertiseNextMap, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Stop;
}

DisplayNextMapToAll()
{
	//If there is a winner to the vote display the winner if not display the next map in rotation
	if(g_iWinningMapIndex >= 0)
	{
		if(g_iNextMapAdDisplayMode == DISPLAY_MODE_HINT)
		{
			//Display the map that is currently winning the vote to all the players using hint text
			if(g_iGameMode == GAMEMODE_SCAVENGE)
				PrintHintTextToAll("The next map is currently %s\nType !mapvote to vote.", g_strScavengeMapName[g_iWinningMapIndex]);
			else
				PrintHintTextToAll("The next campaign is currently %s\nType !mapvote to vote.", g_strCampaignName[g_iWinningMapIndex]);
		}
		else if(g_iNextMapAdDisplayMode == DISPLAY_MODE_CHAT)
		{
			//Display the map that is currently winning the vote to all the players using chat text
			if(g_iGameMode == GAMEMODE_SCAVENGE)
				PrintToChatAll("\x04[ACS] \x01The next map is: \x04%s. \x01Type \x03!mapvote \x01to vote.", g_strScavengeMapName[g_iWinningMapIndex]);
			else
				PrintToChatAll("\x04[ACS] \x01The next campaign is: \x04%s. \x01Type \x03!mapvote \x01to vote.", g_strCampaignName[g_iWinningMapIndex]);
		}
	}
	else
	{
		decl String:strCurrentMap[32];
		GetCurrentMap(strCurrentMap, 32);					//Get the current map from the game
		
		if(g_iGameMode == GAMEMODE_SCAVENGE)
		{
			//Go through all maps and to find which map index it is on, and then switch to the next map
			for(new iMapIndex = 0; iMapIndex < NUMBER_OF_SCAVENGE_MAPS; iMapIndex++)
			{
				if(StrEqual(strCurrentMap, g_strScavengeMap[iMapIndex]) == true)
				{
					if(iMapIndex == NUMBER_OF_SCAVENGE_MAPS - 1)	//Check to see if its the end of the array
						iMapIndex = -1;								//If so, start the array over by setting to -1 + 1 = 0
					
					//Display the next map in the rotation in the appropriate way
					if(g_iNextMapAdDisplayMode == DISPLAY_MODE_HINT)
						PrintHintTextToAll("The next map is currently %s\nType !mapvote to vote.", g_strScavengeMapName[iMapIndex + 1]);
					else if(g_iNextMapAdDisplayMode == DISPLAY_MODE_CHAT)
						PrintToChatAll("\x03[ACS] \x01The next map is: \x04%s. \x01Type \x03!mapvote \x01to vote.", g_strScavengeMapName[iMapIndex + 1]);
				}
			}
		}
		else
		{
			new LastCM = NUMBER_OF_CAMPAIGNS - 1;			//last map in last campaign's array number
			
			//Check to see if this is the end of the array
			if(StrEqual(strCurrentMap, g_strCampaignLastMap[LastCM]) == true)
			{
				//Display the next map in the rotation in the appropriate way
				if(g_iNextMapAdDisplayMode == DISPLAY_MODE_HINT)
					PrintHintTextToAll("The next campaign is currently %s\nType !mapvote to vote.", g_strCampaignName[0]);
				else if(g_iNextMapAdDisplayMode == DISPLAY_MODE_CHAT)
					PrintToChatAll("\x03[ACS] \x01The next campaign is: \x04%s. \x01Type \x05!mapvote \x01to vote.", g_strCampaignName[0]);
			}
			else
			{
				//Go through all maps and to find which map index it is on, and then switch to the next map
				for(new iMapIndex = 0; iMapIndex < NUMBER_OF_CAMPAIGNS; iMapIndex++)
				{
					if(StrEqual(strCurrentMap, g_strCampaignLastMap[iMapIndex]) == true)
					{
						//Display the next map in the rotation in the appropriate way
						if(g_iNextMapAdDisplayMode == DISPLAY_MODE_HINT)
							PrintHintTextToAll("The next campaign is currently %s\nType !mapvote to vote.", g_strCampaignName[iMapIndex + 1]);
						else if(g_iNextMapAdDisplayMode == DISPLAY_MODE_CHAT)
							PrintToChatAll("\x03[ACS] \x01The next campaign is: \x04%s. \x01Type \x05!mapvote \x01to vote.", g_strCampaignName[iMapIndex + 1]);
					}
				}
			}
		}
	}
}

/*======================================================================================
#################              V O T I N G   S Y S T E M               #################
======================================================================================*/

/*======================================================================================
################             P L A Y E R   C O M M A N D S              ################
======================================================================================*/

//Command that a player can use to vote/revote for a map/campaign
public Action:MapVote(iClient, args)
{
	if(g_bVotingEnabled == false)
	{
		PrintToChat(iClient, "\x03[ACS] \x04Voting has been disabled on this server.");
		return;
	}
	
	if(OnFinaleOrScavengeMap() == false)
	{
		PrintToChat(iClient, "\x03[ACS] \x04Voting is only enabled on a Scavenge or finale map.");
		return;
	}
	
	//Open the vote menu for the client if they arent using the server console
	if(iClient < 1)
		PrintToServer("You cannot vote for a map from the server console, use the in-game chat");
	else
		VoteMenuDraw(iClient);
}

//Command that a player can use to see the total votes for all maps/campaigns
public Action:DisplayCurrentVotes(iClient, args)
{
	if(g_bVotingEnabled == false)
	{
		PrintToChat(iClient, "\x03[ACS] \x04Voting has been disabled on this server.");
		return;
	}
	
	if(OnFinaleOrScavengeMap() == false)
	{
		PrintToChat(iClient, "\x03[ACS] \x04Voting is only enabled on a Scavenge or finale map.");
		return;
	}
	
	decl iPlayer, iMap, iNumberOfMaps;
	
	//Get the total number of maps for the current game mode
	if(g_iGameMode == GAMEMODE_SCAVENGE)
		iNumberOfMaps = NUMBER_OF_SCAVENGE_MAPS;
	else
		iNumberOfMaps = NUMBER_OF_CAMPAIGNS;
		
	//Display to the client the current winning map
	if(g_iWinningMapIndex != -1)
	{
		if(g_iGameMode == GAMEMODE_SCAVENGE)
			PrintToChat(iClient, "\x04[ACS] \x03Currently winning the vote: \x04%s", g_strScavengeMapName[g_iWinningMapIndex]);
		else
			PrintToChat(iClient, "\x04[ACS] \x03Currently winning the vote: \x04%s", g_strCampaignName[g_iWinningMapIndex]);
	}
	else
		PrintToChat(iClient, "\x04[ACS] \x03No one has voted yet.");
	
	//Loop through all maps and display the ones that have votes
	new iMapVotes[iNumberOfMaps];
	
	for(iMap = 0; iMap < iNumberOfMaps; iMap++)
	{
		iMapVotes[iMap] = 0;
		
		//Tally votes for the current map
		for(iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
			if(g_iClientVote[iPlayer] == iMap)
				iMapVotes[iMap]++;
		
		//Display this particular map and its amount of votes it has to the client
		if(iMapVotes[iMap] > 0)
		{
			if(g_iGameMode == GAMEMODE_SCAVENGE)
				PrintToChat(iClient, "\x04          %s: \x05%d votes", g_strScavengeMapName[iMap], iMapVotes[iMap]);
			else
				PrintToChat(iClient, "\x04          %s: \x05%d votes", g_strCampaignName[iMap], iMapVotes[iMap]);
		}
	}
}

/*======================================================================================
###############                   V O T E   M E N U                       ##############
======================================================================================*/

//Timer to show the menu to the players if they have not voted yet
public Action:Timer_DisplayVoteAdToAll(Handle:hTimer, any:iData)
{
	if(g_bVotingEnabled == false || OnFinaleOrScavengeMap() == false)
		return Plugin_Stop;
	
	for(new iClient = 1;iClient <= MaxClients; iClient++)
	{
		if(g_bClientShownVoteAd[iClient] == false && g_bClientVoted[iClient] == false && IsClientInGame(iClient) == true && IsFakeClient(iClient) == false)
		{
			switch(g_iVotingAdDisplayMode)
			{
				case DISPLAY_MODE_MENU: VoteMenuDraw(iClient);
				case DISPLAY_MODE_HINT: PrintHintText(iClient, "To vote for the next map, type: !mapvote\nTo see all the votes, type: !mapvotes");
				case DISPLAY_MODE_CHAT: PrintToChat(iClient, "\x03[ACS] \x01To vote for the next map, type: \x04!mapvote\n           \x01To see all the votes, type: \x04!mapvotes");
			}
			
			g_bClientShownVoteAd[iClient] = true;
		}
	}
	
	return Plugin_Stop;
}

//Draw the menu for voting
public Action:VoteMenuDraw(iClient)
{
	if(iClient < 1 || IsClientInGame(iClient) == false || IsFakeClient(iClient) == true)
		return Plugin_Handled;
	
	//Create the menu
	g_hMenu_Vote[iClient] = CreateMenu(VoteMenuHandler);
	
	//Give the player the option of not choosing a map
	AddMenuItem(g_hMenu_Vote[iClient], "option1", "I Don't Care");
	
	//Populate the menu with the maps in rotation for the corresponding game mode
	if(g_iGameMode == GAMEMODE_SCAVENGE)
	{
		SetMenuTitle(g_hMenu_Vote[iClient], "Vote for the next map\n ");

		for(new iCampaign = 0; iCampaign < NUMBER_OF_SCAVENGE_MAPS; iCampaign++)
			AddMenuItem(g_hMenu_Vote[iClient], g_strScavengeMapName[iCampaign], g_strScavengeMapName[iCampaign]);
	}
	else
	{
		SetMenuTitle(g_hMenu_Vote[iClient], "Vote for the next campaign\n ");

		for(new iCampaign = 0; iCampaign < NUMBER_OF_CAMPAIGNS; iCampaign++)
			AddMenuItem(g_hMenu_Vote[iClient], g_strCampaignName[iCampaign], g_strCampaignName[iCampaign]);
	}
	
	//Add an exit button
	SetMenuExitButton(g_hMenu_Vote[iClient], true);
	
	//And finally, show the menu to the client
	DisplayMenu(g_hMenu_Vote[iClient], iClient, MENU_TIME_FOREVER);
	
	//Play a sound to indicate that the user can vote on a map
	EmitSoundToClient(iClient, SOUND_NEW_VOTE_START);
	
	return Plugin_Handled;
}

//Handle the menu selection the client chose for voting
public VoteMenuHandler(Handle:hMenu, MenuAction:maAction, iClient, iItemNum)
{
	if(maAction == MenuAction_Select) 
	{
		g_bClientVoted[iClient] = true;
		
		//Set the players current vote
		if(iItemNum == 0)
			g_iClientVote[iClient] = -1;
		else
			g_iClientVote[iClient] = iItemNum - 1;
			
		//Check to see if theres a new winner to the vote
		SetTheCurrentVoteWinner();
		
		//Display the appropriate message to the voter
		if(iItemNum == 0)
			PrintHintText(iClient, "You did not vote.\nTo vote, type: !mapvote");
		else if(g_iGameMode == GAMEMODE_SCAVENGE)
			PrintHintText(iClient, "You voted for %s.\n- To change your vote, type: !mapvote\n- To see all the votes, type: !mapvotes", g_strScavengeMapName[iItemNum - 1]);
		else
			PrintHintText(iClient, "You voted for %s.\n- To change your vote, type: !mapvote\n- To see all the votes, type: !mapvotes", g_strCampaignName[iItemNum - 1]);
	}
}

//Resets all the menu handles to invalid for every player, until they need it again
CleanUpMenuHandles()
{
	for(new iClient = 0; iClient <= MAXPLAYERS; iClient++)
	{
		if(g_hMenu_Vote[iClient] != INVALID_HANDLE)
		{
			CloseHandle(g_hMenu_Vote[iClient]);
			g_hMenu_Vote[iClient] = INVALID_HANDLE;
		}
	}
}

/*======================================================================================
#########       M I S C E L L A N E O U S   V O T E   F U N C T I O N S        #########
======================================================================================*/

//Resets all the votes for every player
ResetAllVotes()
{
	for(new iClient = 1; iClient <= MaxClients; iClient++)
	{
		g_bClientVoted[iClient] = false;
		g_iClientVote[iClient] = -1;
		
		//Reset so that the player can see the advertisement
		g_bClientShownVoteAd[iClient] = false;
	}
	
	//Reset the winning map to NULL
	g_iWinningMapIndex = -1;
	g_iWinningMapVotes = 0;
}

//Tally up all the votes and set the current winner
SetTheCurrentVoteWinner()
{
	decl iPlayer, iMap, iNumberOfMaps;
	
	//Store the current winnder to see if there is a change
	new iOldWinningMapIndex = g_iWinningMapIndex;
	
	//Get the total number of maps for the current game mode
	if(g_iGameMode == GAMEMODE_SCAVENGE)
		iNumberOfMaps = NUMBER_OF_SCAVENGE_MAPS;
	else
		iNumberOfMaps = NUMBER_OF_CAMPAIGNS;
	
	//Loop through all maps and get the highest voted map	
	new iMapVotes[iNumberOfMaps], iCurrentlyWinningMapVoteCounts = 0, bool:bSomeoneHasVoted = false;
	
	for(iMap = 0; iMap < iNumberOfMaps; iMap++)
	{
		iMapVotes[iMap] = 0;
		
		//Tally votes for the current map
		for(iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
			if(g_iClientVote[iPlayer] == iMap)
				iMapVotes[iMap]++;
		
		//Check if there is at least one vote, if so set the bSomeoneHasVoted to true
		if(bSomeoneHasVoted == false && iMapVotes[iMap] > 0)
			bSomeoneHasVoted = true;
		
		//Check if the current map has more votes than the currently highest voted map
		if(iMapVotes[iMap] > iCurrentlyWinningMapVoteCounts)
		{
			iCurrentlyWinningMapVoteCounts = iMapVotes[iMap];
			
			g_iWinningMapIndex = iMap;
			g_iWinningMapVotes = iMapVotes[iMap];
		}
	}
	
	//If no one has voted, reset the winning map index and votes
	//This is only for if someone votes then their vote is removed
	if(bSomeoneHasVoted == false)
	{
		g_iWinningMapIndex = -1;
		g_iWinningMapVotes = 0;
	}
	
	//If the vote winner has changed then display the new winner to all the players
	if(g_iWinningMapIndex > -1 && iOldWinningMapIndex != g_iWinningMapIndex)
	{
		//Send sound notification to all players
		if(g_bVoteWinnerSoundEnabled == true)
			for(iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
				if(IsClientInGame(iPlayer) == true && IsFakeClient(iPlayer) == false)
					EmitSoundToClient(iPlayer, SOUND_NEW_VOTE_WINNER);
		
		//Show message to all the players of the new vote winner
		if(g_iGameMode == GAMEMODE_SCAVENGE)
			PrintToChatAll("\x03[ACS] \x04%s \x03is now winning the vote.", g_strScavengeMapName[g_iWinningMapIndex]);
		else
			PrintToChatAll("\x03[ACS] \x04%s \x03is now winning the vote.", g_strCampaignName[g_iWinningMapIndex]);
	}
}

//Check if the current map is the last in the campaign if not in the Scavenge game mode
bool:OnFinaleOrScavengeMap()
{
	if(g_iGameMode == GAMEMODE_SCAVENGE)
		return true;
	
	if(g_iGameMode == GAMEMODE_SURVIVAL)
		return false;
	
	decl String:strCurrentMap[32];
	GetCurrentMap(strCurrentMap,32);			//Get the current map from the game
	
	//Run through all the maps, if the current map is a last campaign map, return true
	for(new iMapIndex = 0; iMapIndex < NUMBER_OF_CAMPAIGNS; iMapIndex++)
		if(StrEqual(strCurrentMap, g_strCampaignLastMap[iMapIndex]) == true)
			return true;
	
	return false;
}