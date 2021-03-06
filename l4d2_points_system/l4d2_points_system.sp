#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.8.0"

#define MSGTAG "\x04[PS]\x01"
#define MODULES_SIZE 100

enum
{
	hVersion,
	hEnabled,
	hModes,
	hNotifications,
	hKillSpreeNum,
	hHeadShotNum,
	hTankLimit,
	hWitchLimit,
	hStartPoints,
	hSpawnAttempts,
	hInfectedPlayerLimit
}

enum
{
	CategoryRifles,
	CategorySMG,
	CategorySnipers,
	CategoryShotguns,
	CategoryHealth,
	CategoryUpgrades,
	CategoryThrowables,
	CategoryMisc,
	CategoryMelee,
	CategoryWeapons
}

enum
{
	SurvRewardKillSpree,
	SurvRewardHeadShots,
	SurvKillInfec,
	SurvKillTank,
	SurvKillWitch,
	SurvCrownWitch,
	SurvTeamHeal,
	SurvTeamHealFarm,
	SurvTeamProtect,
	SurvTeamRevive,
	SurvTeamLedge,
	SurvTeamDefib,
	SurvBurnTank,
	SurvBileTank,
	SurvBurnWitch,
	SurvTankSolo,
	InfecChokeSurv,
	InfecPounceSurv,
	InfecChargeSurv,
	InfecImpactSurv,
	InfecRideSurv,
	InfecBoomSurv,
	InfecIncapSurv,
	InfecHurtSurv,
	InfecKillSurv
}

enum
{
	CostP220,
	CostMagnum,
	CostUzi,
	CostSilenced,
	CostMP5,
	CostM16,
	CostAK47,
	CostSCAR,
	CostSG552,
	CostHunting,
	CostMilitary,
	CostAWP,
	CostScout,
	CostAuto,
	CostSPAS,
	CostChrome,
	CostPump,
	CostGrenade,
	CostM60,
	CostGasCan,
	CostOxygen,
	CostPropane,
	CostGnome,
	CostCola,
	CostFireworks,
	CostKnife,
	CostCricketbat,
	CostCrowbar,
	CostElectricguitar,
	CostFireaxe,
	CostFryingpan,
	CostGolfclub,
	CostBaseballbat,
	CostKatana,
	CostMachete,
	CostTonfa,
	CostRiotshield,
	CostPitchfork,
	CostShovel,
	CostCustomMelee,
	CostChainsaw,
	CostPipe,
	CostMolotov,
	CostBile,
	CostHealthKit,
	CostDefib,
	CostAdren,
	CostPills,
	CostExplosiveAmmo,
	CostFireAmmo,
	CostExplosivePack,
	CostFirePack,
	CostLaserSight,
	CostAmmo,
	CostHeal,
	CostSuicide,
	CostHunter,
	CostJockey,
	CostSmoker,
	CostCharger,
	CostBoomer,
	CostSpitter,
	CostInfectedHeal,
	CostWitch,
	CostTank,
	CostTankHealMultiplier,
	CostHorde,
	CostMob,
	CostUncommonMob,
	CostInfectedSlot
}

enum
{
	iTanksSpawned,
	iWitchesSpawned,
	iUCommonLeft
}

int CounterData[3];

void InitCounterData()
{
	CounterData[iTanksSpawned] = 0;
	CounterData[iWitchesSpawned] = 0;
}

enum struct esPlayerData
{
	bool bMessageSent; // Whether welcome message has been displayed to player or not
	bool bPointsLoaded; // Whether a player's points have been loaded from the Clientprefs database
	bool bWitchBurning; // Whether a player has ignited a witch on fire or not
	bool bTankBurning; // Whether a player has ignited a tank on fire or not
	char sBought[64]; // Last purchased item (redundant)
	char sItemName[64]; // The item the player intends to purchase
	int iBoughtCost; // Cost of last purchased item (redundant)
	int iItemCost; // The cost of an item the player intends to purchase
	int iPlayerPoints; // Amount of spendable points
	int iProtectCount; // Number of times player has protected a team mate
	int iKillCount; // Kills made as a survivor
	int iHeadShotCount; // Headshots dealt to infected as a survivor
	int iHurtCount; // Damage dealt to survivors while infected
}

esPlayerData g_esPlayerData[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "Points System",
	author = "McFlurry & evilmaniac and modified by Psykotik",
	description = "Customized edition of McFlurry's points system",
	version = PLUGIN_VERSION,
	url = "http://www.evilmania.net"
}

GlobalForward g_hForward_OnPSLoaded;
GlobalForward g_hForward_OnPSUnloaded;

Database g_hDataBase;

ArrayList ModulesArray;

ConVar PluginSettings[11];
ConVar g_hCategoriesEnabled[10];
ConVar g_hPointRewards[25];
ConVar g_hItemCosts[70];
ConVar g_hGameMode;

float fVersion;

int g_iMeleeClassCount;
int g_iClipSize_RifleM60;
int g_iClipSize_GrenadeLauncher;

bool g_bIsAllowedGameMode;
bool g_bMapTransition;
bool g_bDatabaseLoaded;
bool g_bInDisconnect[MAXPLAYERS + 1];

char g_sGameMode[64];
char g_sCurrentMap[64];
char g_sSteamId[MAXPLAYERS + 1][64];
char g_sMeleeClass[16][32];

static const char g_sMeleeModels[][] =
{
	"models/weapons/melee/v_bat.mdl",
	"models/weapons/melee/w_bat.mdl",
	"models/weapons/melee/v_cricket_bat.mdl",
	"models/weapons/melee/w_cricket_bat.mdl",
	"models/weapons/melee/v_crowbar.mdl",
	"models/weapons/melee/w_crowbar.mdl",
	"models/weapons/melee/v_electric_guitar.mdl",
	"models/weapons/melee/w_electric_guitar.mdl",
	"models/weapons/melee/v_fireaxe.mdl",
	"models/weapons/melee/w_fireaxe.mdl",
	"models/weapons/melee/v_frying_pan.mdl",
	"models/weapons/melee/w_frying_pan.mdl",
	"models/weapons/melee/v_golfclub.mdl",
	"models/weapons/melee/w_golfclub.mdl",
	"models/weapons/melee/v_katana.mdl",
	"models/weapons/melee/w_katana.mdl",
	"models/weapons/melee/v_machete.mdl",
	"models/weapons/melee/w_machete.mdl",
	"models/weapons/melee/v_tonfa.mdl",
	"models/weapons/melee/w_tonfa.mdl",
	"models/weapons/melee/v_riotshield.mdl",
	"models/weapons/melee/w_riotshield.mdl",
	"models/weapons/melee/v_pitchfork.mdl",
	"models/weapons/melee/w_pitchfork.mdl",
	"models/weapons/melee/v_shovel.mdl",
	"models/weapons/melee/w_shovel.mdl"
};

static const char g_sMeleeName[][] =
{
	"knife",			//??????
	"cricket_bat",		//??????
	"crowbar",			//??????
	"electric_guitar",	//??????
	"fireaxe",			//??????
	"frying_pan",		//?????????
	"golfclub",			//???????????????
	"baseball_bat",		//?????????
	"katana",			//?????????
	"machete",			//??????
	"tonfa",			//??????
	"riotshield",		//??????
	"pitchfork",		//??????
	"shovel"			//??????
};

void InitPlayerData(int client)
{
	if(client <= MaxClients)
	{
		g_esPlayerData[client].bMessageSent = false;
		g_esPlayerData[client].bPointsLoaded = false;
		g_esPlayerData[client].bWitchBurning = false;
		g_esPlayerData[client].bTankBurning = false;

		g_esPlayerData[client].iBoughtCost = 0;
		g_esPlayerData[client].iItemCost = 0;
		g_esPlayerData[client].iPlayerPoints = 0;
		g_esPlayerData[client].iProtectCount 	= 0;
		g_esPlayerData[client].iKillCount = 0;
		g_esPlayerData[client].iHeadShotCount = 0;
		g_esPlayerData[client].iHurtCount = 0;
		InitPlayerData(++client);
	}
}

void InitAllPlayerData()
{
	InitPlayerData(1);
}

void InitPluginSprites()
{
	PrecacheModel("sprites/laserbeam.vmt");
	PrecacheModel("sprites/glow01.vmt");
}

void InitPluginSettings()
{
	fVersion = 1.80;

	PluginSettings[hVersion] = CreateConVar("em_points_sys_version", PLUGIN_VERSION, "Version of Points System on this server.", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_REPLICATED);
	PluginSettings[hStartPoints] = CreateConVar("l4d2_points_start", "10", "Points to start each round/map with.");
	PluginSettings[hNotifications] = CreateConVar("l4d2_points_notify", "0", "Show messages when points are earned?");
	PluginSettings[hEnabled] = CreateConVar("l4d2_points_enable", "1", "Enable Point System?");
	PluginSettings[hModes] = CreateConVar("l4d2_points_modes", "coop,realism", "Which game modes to use Point System");
	PluginSettings[hTankLimit] = CreateConVar("l4d2_points_tank_limit", "1", "How many tanks to be allowed spawned per team");
	PluginSettings[hWitchLimit] = CreateConVar("l4d2_points_witch_limit", "5", "How many witches to be allowed spawned per team");
	PluginSettings[hSpawnAttempts] = CreateConVar("l4d2_points_spawn_tries", "2", "How many times to attempt respawning when buying an special infected");
	PluginSettings[hKillSpreeNum] = CreateConVar("l4d2_points_cikills", "15", "How many kills you need to earn a killing spree bounty");
	PluginSettings[hHeadShotNum] = CreateConVar("l4d2_points_headshots", "15", "How many headshot kills you need to earn a head hunter bonus");
	PluginSettings[hInfectedPlayerLimit] = CreateConVar("l4d2_points_infectedplayer_limit", "3", "How many infectedplayers to be allowed");
}

void InitCategoriesEnabled()
{
	g_hCategoriesEnabled[CategoryRifles] = CreateConVar("l4d2_points_cat_rifles", "1", "Enable rifles category");
	g_hCategoriesEnabled[CategorySMG] = CreateConVar("l4d2_points_cat_smg", "1", "Enable smg category");
	g_hCategoriesEnabled[CategorySnipers] = CreateConVar("l4d2_points_cat_snipers", "1", "Enable snipers category");
	g_hCategoriesEnabled[CategoryShotguns] = CreateConVar("l4d2_points_cat_shotguns", "1", "Enable shotguns category");
	g_hCategoriesEnabled[CategoryHealth] = CreateConVar("l4d2_points_cat_health", "1", "Enable health category");
	g_hCategoriesEnabled[CategoryUpgrades] = CreateConVar("l4d2_points_cat_upgrades", "1", "Enable upgrades category");
	g_hCategoriesEnabled[CategoryThrowables] = CreateConVar("l4d2_points_cat_throwables", "1", "Enable throwables category");
	g_hCategoriesEnabled[CategoryMisc] = CreateConVar("l4d2_points_cat_misc", "1", "Enable misc category");
	g_hCategoriesEnabled[CategoryMelee] = CreateConVar("l4d2_points_cat_melee", "1", "Enable melee category");
	g_hCategoriesEnabled[CategoryWeapons] = CreateConVar("l4d2_points_cat_weapons", "1", "Enable weapons category");
}

void InitPointRewards()
{
	g_hPointRewards[SurvRewardKillSpree] = CreateConVar("l4d2_points_cikill_value", "3", "How many points does killing a certain amount of infected earn");
	g_hPointRewards[SurvRewardHeadShots] = CreateConVar("l4d2_points_headshots_value", "5", "How many points does killing a certain amount of infected with headshots earn");
	g_hPointRewards[SurvKillInfec] = CreateConVar("l4d2_points_sikill", "1", "How many points does killing a special infected earn");
	g_hPointRewards[SurvKillTank] = CreateConVar("l4d2_points_tankkill", "5", "How many points does killing a tank earn");
	g_hPointRewards[SurvKillWitch] = CreateConVar("l4d2_points_witchkill", "2", "How many points does killing a witch earn");
	g_hPointRewards[SurvCrownWitch] = CreateConVar("l4d2_points_witchcrown", "10", "How many points does crowning a witch earn");
	g_hPointRewards[SurvTeamHeal] = CreateConVar("l4d2_points_heal", "2", "How many points does healing a team mate earn");
	g_hPointRewards[SurvTeamHealFarm] = CreateConVar("l4d2_points_heal_warning", "0", "How many points does healing a team mate who did not need healing earn");
	g_hPointRewards[SurvTeamProtect] = CreateConVar("l4d2_points_protect", "5", "How many points does protecting a team mate earn");
	g_hPointRewards[SurvTeamRevive] = CreateConVar("l4d2_points_revive", "1", "How many points does reviving a team mate earn");
	g_hPointRewards[SurvTeamLedge] = CreateConVar("l4d2_points_ledge", "1", "How many points does reviving a hanging team mate earn");
	g_hPointRewards[SurvTeamDefib] = CreateConVar("l4d2_points_defib_action", "2", "How many points does defibbing a team mate earn");
	g_hPointRewards[SurvBurnTank] = CreateConVar("l4d2_points_tankburn", "0", "How many points does burning a tank earn");
	g_hPointRewards[SurvTankSolo] = CreateConVar("l4d2_points_tanksolo", "5", "How many points does killing a tank single-handedly earn");
	g_hPointRewards[SurvBurnWitch] = CreateConVar("l4d2_points_witchburn", "1", "How many points does burning a witch earn");
	g_hPointRewards[SurvBileTank] = CreateConVar("l4d2_points_bile_tank", "1", "How many points does biling a tank earn");
	g_hPointRewards[InfecChokeSurv] = CreateConVar("l4d2_points_smoke", "1", "How many points does smoking a survivor earn");
	g_hPointRewards[InfecPounceSurv] = CreateConVar("l4d2_points_pounce", "1", "How many points does pouncing a survivor earn");
	g_hPointRewards[InfecChargeSurv] = CreateConVar("l4d2_points_charge", "1", "How many points does charging a survivor earn");
	g_hPointRewards[InfecImpactSurv] = CreateConVar("l4d2_points_impact", "1", "How many points does impacting a survivor earn");
	g_hPointRewards[InfecRideSurv] = CreateConVar("l4d2_points_ride", "1", "How many points does riding a survivor earn");
	g_hPointRewards[InfecBoomSurv] = CreateConVar("l4d2_points_boom", "1", "How many points does booming a survivor earn");
	g_hPointRewards[InfecIncapSurv] = CreateConVar("l4d2_points_incap", "3", "How many points does incapping a survivor earn");
	g_hPointRewards[InfecHurtSurv] = CreateConVar("l4d2_points_damage", "1", "How many points does doing damage earn");
	g_hPointRewards[InfecKillSurv] = CreateConVar("l4d2_points_kill", "25", "How many points does killing a survivor earn");
}

void InitItemCosts()
{
	g_hItemCosts[CostP220] = CreateConVar("l4d2_points_pistol", "5", "How many points the p220 pistol costs");
	g_hItemCosts[CostMagnum] = CreateConVar("l4d2_points_magnum", "10", "How many points the magnum pistol costs");
	g_hItemCosts[CostUzi] = CreateConVar("l4d2_points_smg", "10", "How many points the smg costs");
	g_hItemCosts[CostSilenced] = CreateConVar("l4d2_points_silenced", "10", "How many points the silenced smg costs");
	g_hItemCosts[CostMP5] = CreateConVar("l4d2_points_mp5", "10", "How many points the mp5 smg costs");
	g_hItemCosts[CostM16] = CreateConVar("l4d2_points_m16", "12", "How many points the m16 rifle costs");
	g_hItemCosts[CostAK47] = CreateConVar("l4d2_points_ak47", "15", "How many points the ak47 rifle costs");
	g_hItemCosts[CostSCAR] = CreateConVar("l4d2_points_scar", "12", "How many points the scar-l rifle costs");
	g_hItemCosts[CostSG552] = CreateConVar("l4d2_points_sg552", "12", "How many points the sg552 rifle costs");
	g_hItemCosts[CostMilitary] = CreateConVar("l4d2_points_military", "20", "How many points the military sniper rifle costs");
	g_hItemCosts[CostAWP] = CreateConVar("l4d2_points_awp", "150", "How many points the awp sniper rifle costs");
	g_hItemCosts[CostScout] = CreateConVar("l4d2_points_scout", "20", "How many points the scout sniper rifle costs");
	g_hItemCosts[CostHunting] = CreateConVar("l4d2_points_hunting", "20", "How many points the hunting rifle costs");
	g_hItemCosts[CostAuto] = CreateConVar("l4d2_points_auto", "20", "How many points the autoshotgun costs");
	g_hItemCosts[CostSPAS] = CreateConVar("l4d2_points_spas", "20", "How many points the spas shotgun costs");
	g_hItemCosts[CostChrome] = CreateConVar("l4d2_points_chrome", "10", "How many points the chrome shotgun costs");
	g_hItemCosts[CostPump] = CreateConVar("l4d2_points_pump", "10", "How many points the pump shotgun costs");
	g_hItemCosts[CostGrenade] = CreateConVar("l4d2_points_grenade", "100", "How many points the grenade launcher costs");
	g_hItemCosts[CostM60] = CreateConVar("l4d2_points_m60", "100", "How many points the m60 rifle costs");
	g_hItemCosts[CostGasCan] = CreateConVar("l4d2_points_gascan", "100", "How many points the gas can costs");
	g_hItemCosts[CostOxygen] = CreateConVar("l4d2_points_oxygen", "100", "How many points the oxgen tank costs");
	g_hItemCosts[CostPropane] = CreateConVar("l4d2_points_propane", "100", "How many points the propane tank costs");
	g_hItemCosts[CostGnome] = CreateConVar("l4d2_points_gnome", "15", "How many points the gnome costs");
	g_hItemCosts[CostCola] = CreateConVar("l4d2_points_cola", "100", "How many points cola bottles costs");
	g_hItemCosts[CostFireworks] = CreateConVar("l4d2_points_fireworks", "100", "How many points the fireworks crate costs");
	g_hItemCosts[CostKnife] = CreateConVar("l4d2_points_knife", "10", "How many points the knife costs");
	g_hItemCosts[CostCricketbat] = CreateConVar("l4d2_points_cricketbat", "10", "How many points the cricket bat costs");
	g_hItemCosts[CostCrowbar] = CreateConVar("l4d2_points_crowbar", "10", "How many points the crowbar costs");
	g_hItemCosts[CostElectricguitar] = CreateConVar("l4d2_points_electricguitar", "10", "How many points the electric guitar costs");
	g_hItemCosts[CostFireaxe] = CreateConVar("l4d2_points_fireaxe", "10", "How many points the fire axe costs");
	g_hItemCosts[CostFryingpan] = CreateConVar("l4d2_points_fryingpan", "10", "How many points the frying pan costs");
	g_hItemCosts[CostGolfclub] = CreateConVar("l4d2_points_golfclub", "10", "How many points the golf club costs");
	g_hItemCosts[CostBaseballbat] = CreateConVar("l4d2_points_baseballbat", "10", "How many points the baseball bat costs");
	g_hItemCosts[CostKatana] = CreateConVar("l4d2_points_katana", "10", "How many points the katana costs");
	g_hItemCosts[CostMachete] = CreateConVar("l4d2_points_machete", "10", "How many points the machete costs");
	g_hItemCosts[CostTonfa] = CreateConVar("l4d2_points_tonfa", "10", "How many points the nightstick costs");
	g_hItemCosts[CostRiotshield] = CreateConVar("l4d2_points_riotshield", "10", "How many points the riotshield costs");
	g_hItemCosts[CostPitchfork] = CreateConVar("l4d2_points_pitchfork", "10", "How many points the pitchfork costs");
	g_hItemCosts[CostShovel] = CreateConVar("l4d2_points_shovel", "10", "How many points the shovel costs");
	g_hItemCosts[CostCustomMelee] = CreateConVar("l4d2_points_custommelee", "50", "How many points the custommelee costs");
	g_hItemCosts[CostChainsaw] = CreateConVar("l4d2_points_chainsaw", "10", "How many points the chainsaw costs");
	g_hItemCosts[CostPipe] = CreateConVar("l4d2_points_pipe", "10", "How many points the pipe bomb costs");
	g_hItemCosts[CostMolotov] = CreateConVar("l4d2_points_molotov", "100", "How many points the molotov costs");
	g_hItemCosts[CostBile] = CreateConVar("l4d2_points_bile", "10", "How many points the bile jar costs");
	g_hItemCosts[CostHealthKit] = CreateConVar("l4d2_points_medkit", "25", "How many points the health kit costs");
	g_hItemCosts[CostDefib] = CreateConVar("l4d2_points_defib", "30", "How many points the defib costs");
	g_hItemCosts[CostAdren] = CreateConVar("l4d2_points_adrenaline", "10", "How many points the adrenaline costs");
	g_hItemCosts[CostPills] = CreateConVar("l4d2_points_pills", "10", "How many points the pills costs");
	g_hItemCosts[CostExplosiveAmmo] = CreateConVar("l4d2_points_explosive_ammo", "15", "How many points the explosive ammo costs");
	g_hItemCosts[CostFireAmmo] = CreateConVar("l4d2_points_incendiary_ammo", "15", "How many points the incendiary ammo costs");
	g_hItemCosts[CostExplosivePack] = CreateConVar("l4d2_points_explosive_ammo_pack", "20", "How many points the explosive ammo pack costs");
	g_hItemCosts[CostFirePack] = CreateConVar("l4d2_points_incendiary_ammo_pack", "20", "How many points the incendiary ammo pack costs");
	g_hItemCosts[CostLaserSight] = CreateConVar("l4d2_points_laser", "10", "How many points the laser sight costs");
	g_hItemCosts[CostHeal] = CreateConVar("l4d2_points_survivor_heal", "35", "How many points a complete heal costs");
	g_hItemCosts[CostAmmo] = CreateConVar("l4d2_points_refill", "10", "How many points an ammo refill costs");

	g_hItemCosts[CostSuicide] = CreateConVar("l4d2_points_suicide", "5", "How many points does suicide cost");
	g_hItemCosts[CostHunter] = CreateConVar("l4d2_points_hunter", "80", "How many points does a hunter cost");
	g_hItemCosts[CostJockey] = CreateConVar("l4d2_points_jockey", "80", "How many points does a jockey cost");
	g_hItemCosts[CostSmoker] = CreateConVar("l4d2_points_smoker", "70", "How many points does a smoker cost");
	g_hItemCosts[CostCharger] = CreateConVar("l4d2_points_charger", "100", "How many points does a charger cost");
	g_hItemCosts[CostBoomer] = CreateConVar("l4d2_points_boomer", "50", "How many points does a boomer cost");
	g_hItemCosts[CostSpitter] = CreateConVar("l4d2_points_spitter", "60", "How many points does a spitter cost");
	g_hItemCosts[CostInfectedHeal] = CreateConVar("l4d2_points_infected_heal", "200", "How many points does healing yourself as an infected cost");
	g_hItemCosts[CostWitch] = CreateConVar("l4d2_points_witch", "100", "How many points does a witch cost");
	g_hItemCosts[CostTank] = CreateConVar("l4d2_points_tank", "1000", "How many points does a tank cost");
	g_hItemCosts[CostTankHealMultiplier] = CreateConVar("l4d2_points_tank_heal_mult", "3", "How much l4d2_points_infected_heal should be multiplied for tank players");
	g_hItemCosts[CostHorde] = CreateConVar("l4d2_points_horde", "200", "How many points does a horde cost");
	g_hItemCosts[CostMob] = CreateConVar("l4d2_points_mob", "200", "How many points does a mob cost");
	g_hItemCosts[CostUncommonMob] = CreateConVar("l4d2_points_umob", "200", "How many points does an uncommon mob cost");
	g_hItemCosts[CostInfectedSlot] = CreateConVar("l4d2_points_infectedslot", "50", "How many points does an infectedslot cost");
}

void InitStructures()
{
	InitPluginSettings();
	InitCategoriesEnabled();
	InitPointRewards();
	InitItemCosts();
	InitAllPlayerData();
	InitPluginSprites();
	InitCounterData();
}

void RegisterAdminCommands()
{
	RegAdminCmd("sm_listmodules", ListModules, ADMFLAG_GENERIC, "List modules currently loaded to Points System");
	RegAdminCmd("sm_listpoints", ListPoints, ADMFLAG_ROOT, "List each player's points.");
	RegAdminCmd("sm_heal", Command_Heal, ADMFLAG_SLAY, "sm_heal <target>");
	RegAdminCmd("sm_givepoints", Command_Points, ADMFLAG_ROOT, "sm_givepoints <target> [amount]");
	RegAdminCmd("sm_setpoints", Command_SPoints, ADMFLAG_ROOT, "sm_setpoints <target> [amount]");
	RegAdminCmd("sm_delold",	Command_DelOld,	ADMFLAG_ROOT, "sm_delold <days> ?????????????????????????????????????????????");
}

void RegisterConsoleCommands()
{
	RegConsoleCmd("sm_buystuff", BuyMenu, "Open the buy menu (only in-game)");
	RegConsoleCmd("sm_repeatbuy", Command_RBuy, "Repeat your last buy transaction");
	RegConsoleCmd("sm_buy", BuyMenu, "Open the buy menu (only in-game)");
	RegConsoleCmd("sm_shop", BuyMenu, "Open the buy menu (only in-game)");
	RegConsoleCmd("sm_store", BuyMenu, "Open the buy menu (only in-game)");
	RegConsoleCmd("sm_points", ShowPoints, "Show the amount of points you have (only in-game)");
}

void HookEvents()
{
	HookEvent("infected_death", Event_Kill);
	HookEvent("player_incapacitated", Event_Incap);
	HookEvent("player_death", Event_Death);
	HookEvent("tank_killed", Event_TankDeath);
	HookEvent("witch_killed", Event_WitchDeath);
	HookEvent("heal_success", Event_Heal);
	HookEvent("award_earned", Event_Protect);
	HookEvent("revive_success", Event_Revive);
	HookEvent("defibrillator_used", Event_Shock);
	HookEvent("choke_start", Event_Choke);
	HookEvent("player_now_it", Event_Boom);
	HookEvent("lunge_pounce", Event_Pounce);
	HookEvent("jockey_ride", Event_Ride);
	HookEvent("charger_carry_start", Event_Carry);
	HookEvent("charger_impact", Event_Impact);
	HookEvent("player_hurt", Event_Hurt);
	HookEvent("zombie_ignited", Event_Burn);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("map_transition", Event_MapTransition, EventHookMode_PostNoCopy);
	HookEvent("finale_win", Event_MapTransition, EventHookMode_PostNoCopy);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
}

public void OnPluginStart()
{
	ModulesArray = new ArrayList(10); // Reduced from 100 to 10.
	if(ModulesArray == null)
		SetFailState("Modules Array Failure");

	AddMultiTargetFilter("@s", FilterSurvivors, "all Survivor players", true);
	AddMultiTargetFilter("@survivor", FilterSurvivors, "all Survivor players", true);
	AddMultiTargetFilter("@survivors", FilterSurvivors, "all Survivor players", true);
	AddMultiTargetFilter("@i", FilterInfected, "all Infected players", true);
	AddMultiTargetFilter("@infected", FilterInfected, "all Infected players", true);

	RegisterAdminCommands();
	RegisterConsoleCommands();
	HookEvents();
	InitStructures();

	g_hGameMode = FindConVar("mp_gamemode");
	g_hGameMode.AddChangeHook(ConVarChanged_GameMode);
	
	if(!g_bDatabaseLoaded)
	{
		g_bDatabaseLoaded = true;
		IniSQLite();
	}
}

public void OnConfigsExecuted()
{
	GetModeCvars();
}

public void ConVarChanged_GameMode(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetModeCvars();
}

void GetModeCvars()
{
	char sEnabledModes[256];
	g_hGameMode.GetString(g_sGameMode, sizeof(g_sGameMode));
	PluginSettings[hModes].GetString(sEnabledModes, sizeof(sEnabledModes));
	g_bIsAllowedGameMode = !!(StrContains(sEnabledModes, g_sGameMode) != -1);
}

void IniSQLite()
{	
	char Error[1024];
	if((g_hDataBase = SQLite_UseDatabase("PointsSystem", Error, sizeof(Error))) == null)
		SetFailState("Could not connect to the database \"PointsSystem\" at the following error:\n%s", Error);
	else
		SQL_FastQuery(g_hDataBase, "CREATE TABLE IF NOT EXISTS PS_Core(SteamID NVARCHAR(64) NOT NULL DEFAULT '', PlayerName NVARCHAR(128) NOT NULL DEFAULT '', Points INT NOT NULL DEFAULT 0, UnixTime INT NOT NULL DEFAULT 0);");
}

int GetAttackerIndex(Event event)
{
	return GetClientOfUserId(event.GetInt("attacker"));
}

int GetClientIndex(Event event)
{
	return GetClientOfUserId(event.GetInt("userid"));
}

bool IsClientPlaying(int client)
{
	return client && IsClientInGame(client) && GetClientTeam(client) > 1;
}

bool IsRealClient(int client)
{
	return client && IsClientInGame(client) && !IsFakeClient(client);
}

bool IsGhost(int client)
{
	return client && GetEntProp(client, Prop_Send, "m_isGhost") == 1;
}

bool IsTank(int client)
{
	return client && GetEntProp(client, Prop_Send, "m_zombieClass") == 8;
}

bool IsSurvivor(int client)
{
	return client && GetClientTeam(client) == 2;
}

bool IsInfected(int client)
{
	return client && GetClientTeam(client) == 3;
}

bool IsModEnabled()
{
	return PluginSettings[hEnabled].IntValue == 1 && g_bIsAllowedGameMode;
}

void SetStartPoints(int client)
{
	g_esPlayerData[client].iPlayerPoints = PluginSettings[hStartPoints].IntValue;
}

void AddPoints(int client, int iPoints, const char[] sMessage)
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client))
	{
		g_esPlayerData[client].iPlayerPoints += iPoints;
		if(PluginSettings[hNotifications].BoolValue)
			PrintToChat(client, "%s %T", MSGTAG, sMessage, client, iPoints);
	}
}

void RemovePoints(int client, int iPoints)
{
	g_esPlayerData[client].iPlayerPoints -= iPoints;
}

public bool FilterSurvivors(const char[] pattern, Handle clients)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2)
			PushArrayCell(clients, i);
	}

	return true;
}

public bool FilterInfected(const char[] pattern, Handle clients)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 3)
			PushArrayCell(clients, i);
	}

	return true;
}

public void OnAllPluginsLoaded()
{
	Call_StartForward(g_hForward_OnPSLoaded);
	Call_Finish();
}

public void OnMapStart()
{
	GetCurrentMap(g_sCurrentMap, sizeof(g_sCurrentMap));

	InitPluginSprites();

	PrecacheModel("models/w_models/v_rif_m60.mdl", true);
	PrecacheModel("models/w_models/weapons/w_m60.mdl", true);
	PrecacheModel("models/v_models/v_m60.mdl", true);
	PrecacheModel("models/infected/witch_bride.mdl", true);
	PrecacheModel("models/infected/witch.mdl", true);
	PrecacheModel("models/infected/common_male_riot.mdl", true);
	PrecacheModel("models/infected/common_male_ceda.mdl", true);
	PrecacheModel("models/infected/common_male_clown.mdl", true);
	PrecacheModel("models/infected/common_male_mud.mdl", true);
	PrecacheModel("models/infected/common_male_roadcrew.mdl", true);
	PrecacheModel("models/infected/common_male_fallen_survivor.mdl", true);

	int i;
	int iLen;

	iLen = sizeof(g_sMeleeModels);
	for(i = 0; i < iLen; i++)
	{
		if(!IsModelPrecached(g_sMeleeModels[i]))
			PrecacheModel(g_sMeleeModels[i], true);
	}

	iLen = sizeof(g_sMeleeName);
	char sBuffer[32];
	for(i = 0; i < iLen; i++)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "scripts/melee/%s.txt", g_sMeleeName[i]);
		if(!IsGenericPrecached(sBuffer))
			PrecacheGeneric(sBuffer, true);
	}
	
	GetMeleeClasses();
}

stock void GetMeleeClasses()
{
	g_iMeleeClassCount = 0;
	
	int i;
	for(i = 0; i < 16; i++)
		g_sMeleeClass[i][0] = 0;
	
	int iMeleeStringTable = FindStringTable("MeleeWeapons");
	int iCount = GetStringTableNumStrings(iMeleeStringTable);
	
	char sMeleeClass[16][32];
	for(i = 0; i < iCount; i++)
	{
		ReadStringTable(iMeleeStringTable, i, sMeleeClass[i], sizeof(sMeleeClass[]));
		if(IsVaidMelee(sMeleeClass[i]))
			strcopy(g_sMeleeClass[g_iMeleeClassCount++], sizeof(g_sMeleeClass[]), sMeleeClass[i]);
	}
}

stock bool IsVaidMelee(const char[] sWeapon)
{
	bool bIsVaid = false;
	int iEntity = CreateEntityByName("weapon_melee");
	DispatchKeyValue(iEntity, "melee_script_name", sWeapon);
	DispatchSpawn(iEntity);

	char sModelName[PLATFORM_MAX_PATH];
	GetEntPropString(iEntity, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));
	if(StrContains(sModelName, "hunter", false) == -1)
		bIsVaid  = true;

	RemoveEdict(iEntity);
	return bIsVaid;
}

public Action ListPoints(int client, int iNumArguments)
{
	if(iNumArguments == 0)
	{
		for(int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
		{
			if(IsClientInGame(iPlayer) && !IsFakeClient(iPlayer)) 
				ReplyToCommand(client, "%s %N: %d", MSGTAG, iPlayer, g_esPlayerData[iPlayer].iPlayerPoints);
		}
	}
	return Plugin_Handled;
}

public Action ListModules(int client, int iNumArguments)
{
	if(iNumArguments == 0)
	{
		ReplyToCommand(client, "%s %T", MSGTAG, "Modules", client);

		int iNumModules = ModulesArray.Length;
		for(int iModule; iModule < iNumModules; iModule++)
		{
			char sModuleName[MODULES_SIZE];
			ModulesArray.GetString(iModule, sModuleName, MODULES_SIZE);
			if(strlen(sModuleName) > 0)
				ReplyToCommand(client, sModuleName);
		}
	}
	return Plugin_Handled;
}

void LoadTranslationFiles()
{
	LoadTranslations("core.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("points_system.phrases");
	LoadTranslations("points_system_menus.phrases");
}

void CreateNatives()
{
	RegPluginLibrary("ps_natives");

	g_hForward_OnPSLoaded = new GlobalForward("OnPSLoaded", ET_Ignore);
	g_hForward_OnPSUnloaded = new GlobalForward("OnPSUnloaded", ET_Ignore);

	CreateNative("PS_IsSystemEnabled", Native_PS_IsSystemEnabled);
	CreateNative("PS_GetVersion", Native_PS_GetVersion);
	CreateNative("PS_SetPoints", Native_PS_SetPoints);
	CreateNative("PS_SetItem", Native_PS_SetItem);
	CreateNative("PS_SetCost", Native_PS_SetCost);
	CreateNative("PS_SetBought", Native_PS_SetBought);
	CreateNative("PS_SetBoughtCost", Native_PS_SetBoughtCost);
	CreateNative("PS_SetupUMob", Native_PS_SetupUMob);
	CreateNative("PS_GetPoints", Native_PS_GetPoints);
	CreateNative("PS_GetBoughtCost", Native_PS_GetBoughtCost);
	CreateNative("PS_GetCost", Native_PS_GetCost);
	CreateNative("PS_GetItem", Native_PS_GetItem);
	CreateNative("PS_GetBought", Native_PS_GetBought);
	CreateNative("PS_RegisterModule", Native_PS_RegisterModule);
	CreateNative("PS_UnregisterModule", Native_PS_UnregisterModule);
	CreateNative("PS_RemovePoints", Native_PS_RemovePoints);
}

//l4d_info_editor
forward void OnGetWeaponsInfo(int pThis, const char[] classname);
native void InfoEditor_GetString(int pThis, const char[] keyname, char[] dest, int destLen);

/**
 * @link https://sm.alliedmods.net/new-api/sourcemod/AskPluginLoad2
 *
 * @param hPlugin Handle to the plugin.
 * @param bLate Whether or not the plugin was loaded "late" (after map load).
 * @param sError Error message buffer in case load failed.
 * @param iErrorSize Maximum number of characters for error message buffer.
 *
 * @return APLRes_Success for load success, APLRes_Failure or APLRes_SilentFailure otherwise
 */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	LoadTranslationFiles();

	CreateNatives();
	MarkNativeAsOptional("InfoEditor_GetString");
	return APLRes_Success;
}

public void OnGetWeaponsInfo(int pThis, const char[] classname)
{
	static char sResult[64];
	if(strcmp(classname, "weapon_rifle_m60") == 0)
	{
		InfoEditor_GetString(pThis, "clip_size", sResult, sizeof(sResult));
		g_iClipSize_RifleM60 = StringToInt(sResult);
	}
	else if(strcmp(classname, "weapon_grenade_launcher") == 0)
	{
		InfoEditor_GetString(pThis, "clip_size", sResult, sizeof(sResult));
		g_iClipSize_GrenadeLauncher = StringToInt(sResult);
	}
}

public void OnPluginEnd()
{
	SQL_SaveAll();

	Action aResult;
	Call_StartForward(g_hForward_OnPSUnloaded);
	Call_Finish(aResult);
}

public int Native_PS_IsSystemEnabled(Handle plugin, int numParams)
{
	return IsModEnabled();
}

public int Native_PS_RemovePoints(Handle plugin, int numParams)
{
	RemovePoints(GetNativeCell(1), GetNativeCell(2));
}

public int Native_PS_RegisterModule(Handle plugin, int numParams)
{
	int iNumModules = ModulesArray.Length;

	char sNewModuleName[MODULES_SIZE];
	GetNativeString(1, sNewModuleName, MODULES_SIZE);

	// Make sure the module is not already loaded
	for(int iModule; iModule < iNumModules; iModule++)
	{
		char sModuleName[MODULES_SIZE];
		ModulesArray.GetString(iModule, sModuleName, MODULES_SIZE);
		if(strcmp(sModuleName, sNewModuleName) == 0)
			return false;
	}

	ModulesArray.PushString(sNewModuleName);
	return true;
}

public int Native_PS_UnregisterModule(Handle plugin, int numParams)
{
	int iNumModules = ModulesArray.Length;

	char sUnloadModuleName[MODULES_SIZE];
	GetNativeString(1, sUnloadModuleName, MODULES_SIZE);

	for(int iModule; iModule < iNumModules; iModule++)
	{
		char sModuleName[MODULES_SIZE];
		ModulesArray.GetString(iModule, sModuleName, MODULES_SIZE);
		if(strcmp(sModuleName, sUnloadModuleName) == 0)
		{
			ModulesArray.Erase(iModule);
			return true;
		}
	}
	return false;
}

public any Native_PS_GetVersion(Handle plugin, int numParams)
{
	return fVersion;
}

public int Native_PS_SetPoints(Handle plugin, int numParams)
{
	g_esPlayerData[GetNativeCell(1)].iPlayerPoints = GetNativeCell(2);
}

public int Native_PS_SetItem(Handle plugin, int numParams)
{
	GetNativeString(2, g_esPlayerData[GetNativeCell(1)].sItemName, 64);
}

public int Native_PS_SetCost(Handle plugin, int numParams)
{
	g_esPlayerData[GetNativeCell(1)].iItemCost = GetNativeCell(2);
}

public int Native_PS_SetBought(Handle plugin, int numParams)
{
	GetNativeString(2, g_esPlayerData[GetNativeCell(1)].sBought, 64);
}

public int Native_PS_SetBoughtCost(Handle plugin, int numParams)
{
	g_esPlayerData[GetNativeCell(1)].iBoughtCost = GetNativeCell(2);
}

public int Native_PS_SetupUMob(Handle plugin, int numParams)
{
	CounterData[iUCommonLeft] = GetNativeCell(1);
}

public int Native_PS_GetPoints(Handle plugin, int numParams)
{
	return g_esPlayerData[GetNativeCell(1)].iPlayerPoints;
}

public int Native_PS_GetCost(Handle plugin, int numParams)
{
	return g_esPlayerData[GetNativeCell(1)].iItemCost;
}

public int Native_PS_GetBoughtCost(Handle plugin, int numParams)
{
	return g_esPlayerData[GetNativeCell(1)].iBoughtCost;
}

public int Native_PS_GetItem(Handle plugin, int numParams)
{
	SetNativeString(2, g_esPlayerData[GetNativeCell(1)].sItemName, GetNativeCell(3));
}

public int Native_PS_GetBought(Handle plugin, int numParams)
{
	SetNativeString(2, g_esPlayerData[GetNativeCell(1)].sBought, 64);
}

void ResetClientData(int client)
{
	g_esPlayerData[client].iKillCount = 0;
	g_esPlayerData[client].iHurtCount = 0;
	g_esPlayerData[client].iProtectCount = 0;
	g_esPlayerData[client].iHeadShotCount = 0;
	g_esPlayerData[client].bMessageSent = false;
}

public void OnClientAuthorized(int client, const char[] auth)
{
	// TODO: validate "auth" arg. instead of GetClientAuthId()
	// https://sm.alliedmods.net/new-api/clients/OnClientAuthorized
	
	if(client)
		CacheSteamID(client);
}

bool CacheSteamID(int client)
{
	if(g_sSteamId[client][0] == '\0')
	{
		if(!GetClientAuthId(client, AuthId_Steam2, g_sSteamId[client], sizeof(g_sSteamId[])))
			return false;
	}
	return true;
}

public void OnClientDisconnect(int client)
{
	if(g_bMapTransition == true || g_bInDisconnect[client] == true)
		return;
		
	g_bInDisconnect[client] = true;

	if(client && IsClientInGame(client) && !IsFakeClient(client))
		SQL_Save(client);
}

public void OnClientDisconnect_Post(int client)
{
	g_sSteamId[client][0] = '\0';
	ResetClientData(client);
}

public void Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{
	g_bMapTransition = true;
	SQL_SaveAll();
}

void SQL_SaveAll()
{
	for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && !IsFakeClient(i))
			SQL_Save(i);
}

public void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client == 0 || !IsClientInGame(client) || IsFakeClient(client) || g_bInDisconnect[client] == true)
		return;

	g_bInDisconnect[client] = true;

	SQL_Save(client);
}

public void OnClientPostAdminCheck(int client)
{
	if(IsFakeClient(client))
		return;

	g_bInDisconnect[client] = false;
	ResetClientData(client);
	SetStartPoints(client);
	CreateTimer(0.5, Timer_OnClientPost, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_OnClientPost(Handle timer, int client)
{
	if((client = GetClientOfUserId(client)) && IsClientInGame(client) && !IsFakeClient(client))
		SQL_Load(client);
}

void SQL_Save(int client)
{
	if(!CacheSteamID(client))
		return;
	
	static char sQuery[1024];
	static char sPlayerName[MAX_NAME_LENGTH];
	FormatEx(sPlayerName, sizeof(sPlayerName), "%N", client);

	FormatEx(sQuery, sizeof(sQuery), "UPDATE PS_Core SET PlayerName = '%s', Points = %d, UnixTime = %d WHERE SteamID = '%s';", sPlayerName, g_esPlayerData[client].iPlayerPoints, GetTime(), g_sSteamId[client]);
	SQL_FastQuery(g_hDataBase, sQuery);
}

void SQL_Load(int client)
{
	if(!CacheSteamID(client))
		return;
	
	static char sQuery[1024];
	FormatEx(sQuery, sizeof(sQuery), "SELECT * FROM PS_Core WHERE SteamId = '%s';", g_sSteamId[client]);
	SQL_TQuery(g_hDataBase, LoadPlayerData, sQuery, GetClientUserId(client));
}

public void LoadPlayerData(Handle db, Handle results, const char[] error, any client)
{
	if(results == null || (client = GetClientOfUserId(client)) == 0)
		return;

	if(SQL_HasResultSet(results) && SQL_FetchRow(results))
		g_esPlayerData[client].iPlayerPoints = SQL_FetchInt(results, 2);
	else
	{
		static char sQuery[1024];
		static char sPlayerName[MAX_NAME_LENGTH];
		FormatEx(sPlayerName, sizeof(sPlayerName), "%N", client);

		FormatEx(sQuery, sizeof(sQuery), "INSERT INTO PS_Core(SteamID, PlayerName, Points, UnixTime) VALUES ('%s', '%s', %d, %d);", g_sSteamId[client], sPlayerName, g_esPlayerData[client].iPlayerPoints, GetTime());
		SQL_FastQuery(g_hDataBase, sQuery);
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bMapTransition = false;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	InitCounterData();
	SQL_SaveAll();
}

void EventHeadShots(int client)
{
	int iHeadShotReward = g_hPointRewards[SurvRewardHeadShots].IntValue;
	if(iHeadShotReward > 0)
	{
		int iHeadShotsRequired = PluginSettings[hHeadShotNum].IntValue;
		g_esPlayerData[client].iHeadShotCount++;
		if(g_esPlayerData[client].iHeadShotCount >= iHeadShotsRequired)
		{
			AddPoints(client, iHeadShotReward, "Head Hunter");
			g_esPlayerData[client].iHeadShotCount -= iHeadShotsRequired;
		}
	}
}

void EventKillSpree(int client)
{
	int iKillSpreeReward = g_hPointRewards[SurvRewardKillSpree].IntValue;
	if(iKillSpreeReward > 0)
	{
		int iKillSpreeRequired = PluginSettings[hKillSpreeNum].IntValue;
		g_esPlayerData[client].iKillCount++;
		if(g_esPlayerData[client].iKillCount >= iKillSpreeRequired)
		{
			AddPoints(client, iKillSpreeReward, "Killing Spree");
			g_esPlayerData[client].iKillCount -= iKillSpreeRequired;
		}
	}
}

public void Event_Kill(Event event, const char[] name, bool dontBroadcast)
{
	int iAttackerIndex = GetAttackerIndex(event);
	if(IsModEnabled() && IsRealClient(iAttackerIndex))
	{
		if(IsSurvivor(iAttackerIndex))
		{
			if(event.GetBool("headshot"))
				EventHeadShots(iAttackerIndex);

			EventKillSpree(iAttackerIndex);
		}
	}
}

public void Event_Incap(Event event, const char[] name, bool dontBroadcast)
{
	int iAttackerIndex = GetAttackerIndex(event);
	if(IsModEnabled() && IsRealClient(iAttackerIndex))
	{
		if(IsInfected(iAttackerIndex))
		{
			int iIncapPoints = g_hPointRewards[InfecIncapSurv].IntValue;
			if(iIncapPoints > 0)
				AddPoints(iAttackerIndex, iIncapPoints, "Incapped Survivor");
		}
	}
}

public void Event_Death(Event event, const char[] name, bool dontBroadcast)
{
	int iAttackerIndex = GetAttackerIndex(event);
	if(IsModEnabled() && IsRealClient(iAttackerIndex))
	{
		int iVictimIndex = GetClientIndex(event);
		if(IsSurvivor(iAttackerIndex))
		{
			int iInfectedKilledReward = g_hPointRewards[SurvKillInfec].IntValue;
			if(iInfectedKilledReward > 0)
			{
				if(IsInfected(iVictimIndex))
				{ // If the person killed by the survivor is infected
					if(IsTank(iVictimIndex)) // Ignore tank death since it is handled elsewhere
						return;
					else
					{
						EventHeadShots(iAttackerIndex);
						AddPoints(iAttackerIndex, iInfectedKilledReward, "Killed SI");
					}
				}
			}
		}
		else if(IsInfected(iAttackerIndex))
		{
			int iSurvivorKilledReward = g_hPointRewards[InfecKillSurv].IntValue;
			if(iSurvivorKilledReward > 0)
			{
				if(IsSurvivor(iVictimIndex)) // If the person killed by the infected is a survivor
					AddPoints(iAttackerIndex, iSurvivorKilledReward, "Killed Survivor");
			}
		}
	}
}

void EventTankKilled()
{
	int iTankKilledReward = g_hPointRewards[SurvKillTank].IntValue;
	if(iTankKilledReward > 0)
		TankKilledPoints(1, iTankKilledReward, "Killed Tank");
}

void TankKilledPoints(int client, int iPoints, const char[] sMessage)
{
	if(client > 0 && MaxClients >= client)
	{
		if(IsRealClient(client) && IsSurvivor(client) && IsPlayerAlive(client))
			AddPoints(client, iPoints, sMessage);

		TankKilledPoints(++client, iPoints, sMessage);
	}
}

public void Event_TankDeath(Event event, const char[] name, bool dontBroadcast)
{
	int iAttackerIndex = GetAttackerIndex(event);
	if(IsModEnabled() && IsRealClient(iAttackerIndex))
	{
		if(IsSurvivor(iAttackerIndex))
		{
			if(event.GetBool("solo")) // If kill was solo
			{
				int iTankSoloReward = g_hPointRewards[SurvTankSolo].IntValue; // Points to be rewarded for killing a tank, solo
				if(iTankSoloReward > 0) // If solo kill reward is enabled
					AddPoints(iAttackerIndex, iTankSoloReward, "TANK SOLO");
			}
			else
				EventTankKilled(); // Reward survivors for killing a tank
		}
	}
	g_esPlayerData[iAttackerIndex].bTankBurning = false;
}

public void Event_WitchDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientIndex(event);
	if(IsModEnabled() && IsRealClient(client))
	{
		if(IsSurvivor(client))
		{
			int iWitchKilledReward = g_hPointRewards[SurvKillWitch].IntValue;
			if(iWitchKilledReward > 0)
				AddPoints(client, iWitchKilledReward, "Killed Witch");

			if(event.GetBool("oneshot"))
			{
				int iWitchCrownedReward = g_hPointRewards[SurvCrownWitch].IntValue;
				if(iWitchCrownedReward > 0)
					AddPoints(client, iWitchCrownedReward, "Crowned Witch");
			}
		}
	}
	g_esPlayerData[client].bWitchBurning = false;
}

public void Event_Heal(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientIndex(event);
	if(IsModEnabled() && IsRealClient(client))
	{
		if(IsSurvivor(client))
		{
			if(client != GetClientOfUserId(event.GetInt("subject")))
			{ // If player did not heal himself with the medkit
				if(event.GetInt("health_restored") > 39)
				{
					int iHealTeamReward = g_hPointRewards[SurvTeamHeal].IntValue;
					if(iHealTeamReward > 0)
						AddPoints(client, iHealTeamReward, "Team Heal");
				}
				else
				{
					int iHealTeamReward = g_hPointRewards[SurvTeamHealFarm].IntValue;
					if(iHealTeamReward > 0)
						AddPoints(client, iHealTeamReward, "Team Heal Warning");
				}
			}
		}
	}
}

void EventProtect(int client)
{
	int iProtectReward = g_hPointRewards[SurvTeamProtect].IntValue;
	if(iProtectReward > 0)
	{
		g_esPlayerData[client].iProtectCount++;
		if(g_esPlayerData[client].iProtectCount == 6)
		{
			AddPoints(client, iProtectReward, "Protect");
			g_esPlayerData[client].iProtectCount -= 6;
		}
	}
}

public void Event_Protect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientIndex(event);
	if(IsModEnabled() && IsRealClient(client) && IsSurvivor(client) && event.GetInt("award") == 67)
		EventProtect(client);
}

public void Event_Revive(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientIndex(event);
	if(IsModEnabled() && IsRealClient(client) && IsSurvivor(client) && client != GetClientOfUserId(event.GetInt("subject")))
	{
		if(event.GetBool("ledge_hang"))
		{
			int iLedgeReviveReward = g_hPointRewards[SurvTeamLedge].IntValue;
			if(iLedgeReviveReward > 0)
				AddPoints(client, iLedgeReviveReward, "Ledge Revive");
		}
		else
		{
			int iReviveReward = g_hPointRewards[SurvTeamRevive].IntValue;
			if(iReviveReward > 0)
				AddPoints(client, iReviveReward, "Revive");
		}
	}
}

public void Event_Shock(Event event, const char[] name, bool dontBroadcast)
{ // Defib
	int client = GetClientIndex(event);
	if(IsModEnabled() && IsRealClient(client) && IsSurvivor(client))
	{
		int iDefibReward = g_hPointRewards[SurvTeamDefib].IntValue;
		if(iDefibReward > 0)
			AddPoints(client, iDefibReward, "Defib");
	}
}

public void Event_Choke(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientIndex(event);
	if(IsModEnabled() && IsRealClient(client) && IsInfected(client))
	{
		int iChokeReward = g_hPointRewards[InfecChokeSurv].IntValue;
		if(iChokeReward > 0)
			AddPoints(client, iChokeReward, "Smoke");
	}
}

public void Event_Boom(Event event, const char[] name, bool dontBroadcast)
{
	int iAttackerIndex = GetAttackerIndex(event);
	if(IsModEnabled() && IsRealClient(iAttackerIndex))
	{
		if(IsInfected(iAttackerIndex)) // If boomer biles survivors
		{ 
			int iBoomedReward = g_hPointRewards[InfecBoomSurv].IntValue;
			if(iBoomedReward > 0)
				AddPoints(iAttackerIndex, iBoomedReward, "Boom");
		}
		else if(IsSurvivor(iAttackerIndex)) // If survivor biles a tank
		{
			int iBiledReward = g_hPointRewards[SurvBileTank].IntValue;
			if(iBiledReward > 0)
			{
				if(IsTank(GetClientIndex(event)))
					AddPoints(iAttackerIndex, iBiledReward, "Biled");
			}
		}
	}
}

public void Event_Pounce(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientIndex(event);
	if(IsModEnabled() && IsRealClient(client) && IsInfected(client))
	{
		int iPounceReward = g_hPointRewards[InfecPounceSurv].IntValue;
		if(iPounceReward > 0)
			AddPoints(client, iPounceReward, "Pounce");
	}
}

public void Event_Ride(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientIndex(event);
	if(IsModEnabled() && IsRealClient(client) && IsInfected(client))
	{
		int iRideReward = g_hPointRewards[InfecRideSurv].IntValue;
		if(iRideReward > 0)
			AddPoints(client, iRideReward, "Jockey Ride");
	}
}

public void Event_Carry(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientIndex(event);
	if(IsModEnabled() && IsRealClient(client))
	{
		if(IsInfected(client))
		{
			int iCarryReward = g_hPointRewards[InfecChargeSurv].IntValue;
			if(iCarryReward > 0)
				AddPoints(client, iCarryReward, "Charge");
		}
	}
}

public void Event_Impact(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientIndex(event);
	if(IsModEnabled() && IsRealClient(client) && IsInfected(client))
	{
		int iImpactReward = g_hPointRewards[InfecImpactSurv].IntValue;
		if(iImpactReward > 0)
			AddPoints(client, iImpactReward, "Charge Collateral");
	}
}

public void Event_Burn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientIndex(event);
	if(IsModEnabled() && IsRealClient(client))
	{
		if(IsSurvivor(client))
		{
			char sVictimName[30];
			event.GetString("victimname", sVictimName, sizeof(sVictimName));
			if(!strcmp(sVictimName, "Tank", false))
			{
				int iTankBurnReward = g_hPointRewards[SurvBurnTank].IntValue;
				if(iTankBurnReward > 0)
				{
					if(!g_esPlayerData[client].bTankBurning)
					{
						g_esPlayerData[client].bTankBurning = true;
						AddPoints(client, iTankBurnReward, "Burn Tank");
					}
				}
			}
			else if(!strcmp(sVictimName, "Witch", false))
			{
				int iWitchBurnReward = g_hPointRewards[SurvBurnWitch].IntValue;
				if(iWitchBurnReward > 0)
				{
					if(!g_esPlayerData[client].bWitchBurning)
					{
						g_esPlayerData[client].bWitchBurning = true;
						AddPoints(client, iWitchBurnReward, "Burn Witch");
					}
				}
			}
		}
	}
}

void EventSpit(int client, int iPoints)
{
    if(g_esPlayerData[client].iHurtCount >= 8)
	{
        AddPoints(client, iPoints, "Spit Damage");
        g_esPlayerData[client].iHurtCount -= 8;
    }
}

void EventDamage(int client, int iPoints)
{
    if(g_esPlayerData[client].iHurtCount >= 3)
	{
        AddPoints(client, iPoints, "Damage");
        g_esPlayerData[client].iHurtCount -= 3;
    }
}

bool IsFireDamage(int iDamageType)
{
	return iDamageType == 8 || iDamageType == 2056;
}

bool IsSpitterDamage(int iDamageType)
{
   return iDamageType == 263168 || iDamageType == 265216;
}

public void Event_Hurt(Event event, const char[] name, bool dontBroadcast)
{
	int iAttackerIndex = GetAttackerIndex(event);
	if(IsModEnabled() && IsRealClient(iAttackerIndex))
	{
		if(IsInfected(iAttackerIndex) && IsSurvivor(GetClientIndex(event)))
		{
			g_esPlayerData[iAttackerIndex].iHurtCount++;
			int iSurvivorDamagedReward = g_hPointRewards[InfecHurtSurv].IntValue;
			if(iSurvivorDamagedReward > 0)
			{
				int iDamageType = event.GetInt("type");
				if(IsFireDamage(iDamageType)) // If infected is dealing fire damage, ignore
					return;
				else if(IsSpitterDamage(iDamageType))
					EventSpit(iAttackerIndex, iSurvivorDamagedReward);
				else
				{
					if(!IsSpitterDamage(iDamageType))
						EventDamage(iAttackerIndex, iSurvivorDamagedReward);
				}
			}
		}
	}
}

public Action BuyMenu(int client, int iNumArguments)
{
	if(IsModEnabled() && iNumArguments == 0)
	{
		if(IsClientPlaying(client))
			BuildBuyMenu(client);
	}
	return Plugin_Handled;
}

public Action ShowPoints(int client, int iNumArguments)
{
	if(IsModEnabled() && iNumArguments == 0)
	{
		if(IsClientPlaying(client))
			ReplyToCommand(client, "%s %T", MSGTAG, "Your Points", client, g_esPlayerData[client].iPlayerPoints);
	}
	return Plugin_Handled;
}

bool CheckPurchase(int client, int iCost)
{
	return client > 0 && IsItemEnabled(client, iCost) && HasEnoughPoints(client, iCost);
}

bool IsItemEnabled(int client, int iCost)
{
	if(client > 0)
	{
		if(iCost >= 0)
			return true;
		else
		{
			ReplyToCommand(client, "%s %T", MSGTAG, "Item Disabled", client);
			return false;
		}
	}
	return false;
}

bool HasEnoughPoints(int client, int iCost)
{
	if(client > 0)
	{
		if(g_esPlayerData[client].iPlayerPoints >= iCost)
			return true;
		else
		{
			ReplyToCommand(client, "%s %T", MSGTAG, "Insufficient Funds", client);
			return false;
		}
	}
	return false;
}

void JoinInfected(int client, int iCost)
{
	if(IsRealClient(client))
	{
		if(IsSurvivor(client))
		{
			ChangeClientTeam(client, 3);
			RemovePoints(client, iCost);
		}
	}
}

void PerformSuicide(int client, int iCost)
{
	if(IsRealClient(client))
	{
		if(IsInfected(client))
		{
			ForcePlayerSuicide(client);
			RemovePoints(client, iCost);
		}
	}
}

public Action Command_RBuy(int client, int iNumArguments)
{
	if(client > 0 && iNumArguments == 0)
	{
		if(IsRealClient(client) && GetClientTeam(client) > 1)
		{
			if(CheckPurchase(client, g_esPlayerData[client].iItemCost))
			{ // Check if item is Enabled & Player has points
				if(!strcmp(g_esPlayerData[client].sItemName, "suicide", false))
				{
					PerformSuicide(client, g_esPlayerData[client].iItemCost);
					return Plugin_Handled;
				}
				else
				{ // If we are not dealing with a suicide
					CheatCommand(client, g_esPlayerData[client].sItemName);
					RemovePoints(client, g_esPlayerData[client].iItemCost);
					//do additional actions for certain items
					if(!strcmp(g_esPlayerData[client].sItemName, "z_spawn_old mob", false))
					{
						CounterData[iUCommonLeft] += FindConVar("z_common_limit").IntValue;
					}
					else if(!strcmp(g_esPlayerData[client].sItemName, "give ammo", false))
					{
						ReloadAmmo(client, g_esPlayerData[client].iItemCost, g_esPlayerData[client].sItemName);
					}
					return Plugin_Handled;
				}
			}
		}
	}
	return Plugin_Handled;
}

public Action Command_Heal(int client, int args)
{
	if(args == 0)
	{
		CheatCommand(client, "give health");
		return Plugin_Handled;
	}
	else if(args == 1)
	{
		char arg[65];
		GetCmdArg(1, arg, sizeof(arg));
		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;
		if((target_count = ProcessTargetString(
				arg,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_ALIVE,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		else
		{
			ShowActivity2(client, MSGTAG, " %t", "Give Health", target_name);

			for (int i = 0; i < target_count; i++)
			{
				int targetclient = target_list[i];
				CheatCommand(targetclient, "give health");
			}
			return Plugin_Handled;
		}
	}
	else
	{
		ReplyToCommand(client, "%s%T", MSGTAG, "Usage sm_heal", client);
		return Plugin_Handled;
	}
}

public Action Command_Points(int client, int args)
{
	if(args == 2)
	{
		char arg[MAX_NAME_LENGTH], arg2[32];
		GetCmdArg(1, arg, sizeof(arg));
		GetCmdArg(2, arg2, sizeof(arg2));
		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;
		int targetclient, amount = StringToInt(arg2);
		if((target_count = ProcessTargetString(
				arg,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_NO_BOTS,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		else
		{
			for (int i = 0; i < target_count; i++)
			{
				targetclient = target_list[i];
				g_esPlayerData[targetclient].iPlayerPoints += amount;
				SQL_Save(targetclient);
				ReplyToCommand(client, "%s %T", MSGTAG, "Give Points", client, amount, targetclient);
				ReplyToCommand(targetclient, "%s %T", MSGTAG, "Give Target", targetclient, client, amount);
			}
			return Plugin_Handled;
		}
	}
	else
	{
		ReplyToCommand(client, "%s %T", MSGTAG, "Usage sm_givepoints", client);
		return Plugin_Handled;
	}
}

public Action Command_SPoints(int client, int args)
{
	if(args == 2)
	{
		char arg[MAX_NAME_LENGTH], arg2[32];
		GetCmdArg(1, arg, sizeof(arg));
		GetCmdArg(2, arg2, sizeof(arg2));
		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;
		int targetclient, amount = StringToInt(arg2);
		if((target_count = ProcessTargetString(
				arg,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_NO_BOTS,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		else
		{
			//ShowActivity2(client, MSGTAG, "%t", "Set Points", target_name, amount);
			for (int i = 0; i < target_count; i++)
			{
				targetclient = target_list[i];
				g_esPlayerData[targetclient].iPlayerPoints = amount;
				SQL_Save(targetclient);
				ReplyToCommand(client, "%s %T", MSGTAG, "Set Points", client, targetclient, amount);
				ReplyToCommand(targetclient, "%s %T", MSGTAG, "Set Target", targetclient, client, amount);
			}
			return Plugin_Handled;
		}
	}
	else
	{
		ReplyToCommand(client, "%s %T", MSGTAG, "Usage sm_setpoints", client, MSGTAG);
		return Plugin_Handled;
	}
}

public Action Command_DelOld(int client, int args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "sm_delold <days>");
		return Plugin_Handled;
	}
	
	char sDays[8];
	GetCmdArg(1, sDays, sizeof(sDays));
	int iDays = StringToInt(sDays);
	
	int iUnixTime = GetTime();
	iUnixTime -= iDays * 60 * 60 * 24;
	
	char sQuery[1024];
	FormatEx(sQuery, sizeof(sQuery), "DELETE FROM PS_Core WHERE UnixTime < %i;", iUnixTime);
	SQL_FastQuery(g_hDataBase, sQuery);
	return Plugin_Handled;
}

void CheatCommand(int client, const char[] sCommand)
{
	if(client == 0 || !IsClientInGame(client))
		return;

	char sCmd[32];
	if(SplitString(sCommand, " ", sCmd, sizeof(sCmd)) == -1)
		strcopy(sCmd, sizeof(sCmd), sCommand);

	int bits = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	int flags = GetCommandFlags(sCmd);
	SetCommandFlags(sCmd, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, sCommand);
	SetCommandFlags(sCmd, flags);
	SetUserFlagBits(client, bits);
	if(sCommand[0] == 'g' && strcmp(sCommand[5], "health") == 0)
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0); //??????????????????give health?????????100???
}

void BuildBuyMenu(int client)
{
	if(GetClientTeam(client) == 2)
	{
		char sInfo[32];
		Menu menu = new Menu(TopMenu);
		if(g_hCategoriesEnabled[CategoryWeapons].IntValue == 1)
		{
			FormatEx(sInfo, sizeof(sInfo), "%T", "Weapons", client);
			menu.AddItem("g_WeaponsMenu", sInfo);
		}
		if(g_hCategoriesEnabled[CategoryUpgrades].IntValue == 1)
		{
			FormatEx(sInfo, sizeof(sInfo), "%T", "Upgrades", client);
			menu.AddItem("g_UpgradesMenu", sInfo);
		}
		if(g_hCategoriesEnabled[CategoryHealth].IntValue == 1)
		{
			FormatEx(sInfo, sizeof(sInfo), "%T", "Health", client);
			menu.AddItem("g_HealthMenu", sInfo);
		}
		if(g_hItemCosts[CostInfectedSlot].IntValue > -1)
		{
			FormatEx(sInfo, sizeof(sInfo), "%T", "InfectedSlot", client);
			menu.AddItem("g_InfectedSlot", sInfo);
		}
		
		FormatEx(sInfo, sizeof(sInfo), "%T", "Points Left", client, g_esPlayerData[client].iPlayerPoints);
		menu.SetTitle(sInfo);
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else if(GetClientTeam(client) == 3)
	{
		char sInfo[32];
		Menu menu = new Menu(InfectedMenu);
		if(g_hItemCosts[CostInfectedHeal].IntValue > -1)
		{
			FormatEx(sInfo, sizeof(sInfo), "%T", "Heal", client);
			menu.AddItem("heal", sInfo);
		}
		if(g_hItemCosts[CostSuicide].IntValue > -1)
		{
			FormatEx(sInfo, sizeof(sInfo), "%T", "Suicide", client);
			menu.AddItem("suicide", sInfo);
		}
		if(g_hItemCosts[CostBoomer].IntValue > -1)
		{
			FormatEx(sInfo, sizeof(sInfo), "%T", "Boomer", client);
			menu.AddItem("boomer", sInfo);
		}
		if(g_hItemCosts[CostSpitter].IntValue > -1)
		{
			FormatEx(sInfo, sizeof(sInfo), "%T", "Spitter", client);
			menu.AddItem("spitter", sInfo);
		}
		if(g_hItemCosts[CostSmoker].IntValue > -1)
		{
			FormatEx(sInfo, sizeof(sInfo), "%T", "Smoker", client);
			menu.AddItem("smoker", sInfo);
		}
		if(g_hItemCosts[CostHunter].IntValue > -1)
		{
			FormatEx(sInfo, sizeof(sInfo), "%T", "Hunter", client);
			menu.AddItem("hunter", sInfo);
		}
		if(g_hItemCosts[CostCharger].IntValue > -1)
		{
			FormatEx(sInfo, sizeof(sInfo), "%T", "Charger", client);
			menu.AddItem("charger", sInfo);
		}
		if(g_hItemCosts[CostJockey].IntValue > -1)
		{
			FormatEx(sInfo, sizeof(sInfo), "%T", "Jockey", client);
			menu.AddItem("jockey", sInfo);
		}
		if(g_hItemCosts[CostTank].IntValue > -1)
		{
			FormatEx(sInfo, sizeof(sInfo), "%T", "Tank", client);
			menu.AddItem("tank", sInfo);
		}
		if(!strcmp(g_sCurrentMap, "c6m1_riverbank", false) && g_hItemCosts[CostWitch].IntValue > -1)
		{
			FormatEx(sInfo, sizeof(sInfo), "%T", "Witch Bride", client);
			menu.AddItem("witch_bride", sInfo);
		}
		else if(g_hItemCosts[CostWitch].IntValue > -1)
		{
			FormatEx(sInfo, sizeof(sInfo), "%T", "Witch", client);
			menu.AddItem("witch", sInfo);
		}
		if(g_hItemCosts[CostHorde].IntValue > -1)
		{
			FormatEx(sInfo, sizeof(sInfo), "%T", "Horde", client);
			menu.AddItem("horde", sInfo);
		}
		if(g_hItemCosts[CostMob].IntValue > -1)
		{
			FormatEx(sInfo, sizeof(sInfo), "%T", "Mob", client);
			menu.AddItem("mob", sInfo);
		}
		if(g_hItemCosts[CostUncommonMob].IntValue > -1)
		{
			FormatEx(sInfo, sizeof(sInfo), "%T", "Uncommon Mob", client);
			menu.AddItem("uncommon_mob", sInfo);
		}
		FormatEx(sInfo, sizeof(sInfo), "%T", "Points Left", client, g_esPlayerData[client].iPlayerPoints);
		menu.SetTitle(sInfo);
		menu.Display(client, MENU_TIME_FOREVER);
	}
}

void BuildWeaponsMenu(int client)
{
	char sInfo[32];
	Menu menu = new Menu(MenuHandler);
	menu.ExitBackButton = true;
	if(g_hCategoriesEnabled[CategoryMelee].IntValue == 1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Melee", client);
		menu.AddItem("g_MeleeMenu", sInfo);
	}
	if(g_hCategoriesEnabled[CategorySnipers].IntValue == 1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Sniper Rifles", client);
		menu.AddItem("g_SnipersMenu", sInfo);
	}
	if(g_hCategoriesEnabled[CategoryRifles].IntValue == 1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Assault Rifles", client);
		menu.AddItem("g_RiflesMenu", sInfo);
	}
	if(g_hCategoriesEnabled[CategoryShotguns].IntValue == 1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Shotguns", client);
		menu.AddItem("g_ShotgunsMenu", sInfo);
	}
	if(g_hCategoriesEnabled[CategorySMG].IntValue == 1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Submachine Guns", client);
		menu.AddItem("g_SMGMenu", sInfo);
	}
	if(g_hCategoriesEnabled[CategoryThrowables].IntValue == 1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Throwables", client);
		menu.AddItem("g_ThrowablesMenu", sInfo);
	}
	if(g_hCategoriesEnabled[CategoryMisc].IntValue == 1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Misc", client);
		menu.AddItem("g_MiscMenu", sInfo);
	}
	FormatEx(sInfo, sizeof(sInfo),"%T", "Points Left", client, g_esPlayerData[client].iPlayerPoints);
	menu.SetTitle(sInfo);
	menu.Display(client, MENU_TIME_FOREVER);
}

public int TopMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[32];
			menu.GetItem(param2, sItem, sizeof(sItem));
			if(strcmp(sItem, "g_WeaponsMenu") == 0)
				BuildWeaponsMenu(param1);
			else if(strcmp(sItem, "g_HealthMenu") == 0)
				BuildHealthMenu(param1);
			else if(strcmp(sItem, "g_UpgradesMenu") == 0)
				BuildUpgradesMenu(param1);
			else if(strcmp(sItem, "g_InfectedSlot") == 0)
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "g_InfectedSlot");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostInfectedSlot].IntValue;
				char sInfo[32];
				Menu menu1 = new Menu(MenuHandler_InfectedSlot);
				FormatEx(sInfo, sizeof(sInfo),"%T", "Yes", param1);
				menu1.AddItem("yes", sInfo);
				FormatEx(sInfo, sizeof(sInfo),"%T", "No", param1);
				menu1.AddItem("no", sInfo);
				FormatEx(sInfo, sizeof(sInfo),"%T", "Cost", param1, g_esPlayerData[param1].iItemCost);
				menu1.SetTitle(sInfo);
				menu1.ExitBackButton = true;
				menu1.Display(param1, MENU_TIME_FOREVER);
			}
		}
		case MenuAction_End:
			delete menu;
	}
}

public int MenuHandler_InfectedSlot(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[32];
			menu.GetItem(param2, sItem, sizeof(sItem));
			if(strcmp(sItem, "no", false) == 0)
			{
				BuildBuyMenu(param1);
				strcopy(g_esPlayerData[param1].sItemName, 64, g_esPlayerData[param1].sBought);
				g_esPlayerData[param1].iItemCost = g_esPlayerData[param1].iBoughtCost;
			}
			else if(strcmp(sItem, "yes", false) == 0)
			{
				if(!HasEnoughPoints(param1, g_esPlayerData[param1].iItemCost))
					return;

				if(!strcmp(g_esPlayerData[param1].sItemName, "g_InfectedSlot", false))
				{
					if(GetPlayerZombie() >= PluginSettings[hInfectedPlayerLimit].IntValue)
						PrintToChat(param1,  "%T", "Infected Player Limit", param1);
					else
						JoinInfected(param1, g_esPlayerData[param1].iItemCost);
				}
			}
		}
		case MenuAction_Cancel:
		{
			strcopy(g_esPlayerData[param1].sItemName, 64, g_esPlayerData[param1].sBought);
			g_esPlayerData[param1].iItemCost = g_esPlayerData[param1].iBoughtCost;
		}
		case MenuAction_End:
			delete menu;
	}
}

int GetPlayerZombie()
{
	int iZombie;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 3 && !IsFakeClient(i))
			iZombie++;
	}
	return iZombie;
}

public int MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[32];
			menu.GetItem(param2, sItem, sizeof(sItem));
			if(!strcmp(sItem, "g_MeleeMenu"))
				BuildMeleeMenu(param1);
			else if(!strcmp(sItem, "g_RiflesMenu"))
				BuildRiflesMenu(param1);
			else if(!strcmp(sItem, "g_SnipersMenu"))
				BuildSniperMenu(param1);
			else if(!strcmp(sItem, "g_ShotgunsMenu"))
				BuildShotgunMenu(param1);
			else if(!strcmp(sItem, "g_SMGMenu"))
				BuildSMGMenu(param1);
			else if(!strcmp(sItem, "g_ThrowablesMenu"))
				BuildThrowablesMenu(param1);
			else if(!strcmp(sItem, "g_MiscMenu"))
				BuildMiscMenu(param1);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				BuildBuyMenu(param1);
		}
		case MenuAction_End:
			delete menu;
	}
}

void BuildMeleeMenu(int client)
{
	char sInfo[32];
	Menu menu = new Menu(MenuHandler_Melee);
	for(int i; i < g_iMeleeClassCount; i++)
	{
		int sequence = GetMeleeCost(g_sMeleeClass[i]);
		int cost;
		if(sequence != -1)
			cost = g_hItemCosts[sequence + 25].IntValue;
		else
			cost = g_hItemCosts[CostCustomMelee].IntValue;
		
		if(cost < 1)
			continue;

		if(sequence != -1)
			FormatEx(sInfo, sizeof(sInfo), "%T", g_sMeleeClass[i], client);
		else
			FormatEx(sInfo, sizeof(sInfo), g_sMeleeClass[i]);
		menu.AddItem(g_sMeleeClass[i], sInfo);
	}
	FormatEx(sInfo, sizeof(sInfo),"%T", "Points Left", client, g_esPlayerData[client].iPlayerPoints);
	menu.SetTitle(sInfo);
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

stock int GetMeleeCost(char[] MeleeName)
{
	for(int i; i < sizeof(g_sMeleeName); i++)
	{
		if(strcmp(g_sMeleeName[i], MeleeName) == 0)
			return i;
	}
	return -1;
}

void BuildSniperMenu(int client)
{
	char sInfo[32];
	Menu menu = new Menu(MenuHandler_Snipers);
	if(g_hItemCosts[CostHunting].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Hunting Rifle", client);
		menu.AddItem("weapon_hunting_rifle", sInfo);
	}
	if(g_hItemCosts[CostMilitary].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Military Sniper Rifle", client);
		menu.AddItem("weapon_sniper_military", sInfo);
	}
	if(g_hItemCosts[CostAWP].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "AWP Sniper Rifle", client);
		menu.AddItem("weapon_sniper_awp", sInfo);
	}
	if(g_hItemCosts[CostScout].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Scout Sniper Rifle", client);
		menu.AddItem("weapon_sniper_scout", sInfo);
	}
	FormatEx(sInfo, sizeof(sInfo),"%T", "Points Left", client, g_esPlayerData[client].iPlayerPoints);
	menu.SetTitle(sInfo);
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

void BuildRiflesMenu(int client)
{
	char sInfo[32];
	Menu menu = new Menu(MenuHandler_Rifles);
	if(g_hItemCosts[CostM60].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "M60 Assault Rifle", client);
		menu.AddItem("weapon_rifle_m60", sInfo);
	}
	if(g_hItemCosts[CostM16].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "M16 Assault Rifle", client);
		menu.AddItem("weapon_rifle", sInfo);
	}
	if(g_hItemCosts[CostSCAR].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "SCAR-L Assault Rifle", client);
		menu.AddItem("weapon_rifle_desert", sInfo);
	}
	if(g_hItemCosts[CostAK47].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "AK-47 Assault Rifle", client);
		menu.AddItem("weapon_rifle_ak47", sInfo);
	}
	if(g_hItemCosts[CostSG552].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "SG552 Assault Rifle", client);
		menu.AddItem("weapon_rifle_sg552", sInfo);
	}
	FormatEx(sInfo, sizeof(sInfo),"%T", "Points Left", client, g_esPlayerData[client].iPlayerPoints);
	menu.SetTitle(sInfo);
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

void BuildShotgunMenu(int client)
{
	char sInfo[32];
	Menu menu = new Menu(MenuHandler_Shotguns);
	if(g_hItemCosts[CostAuto].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Tactical Shotgun", client);
		menu.AddItem("weapon_autoshotgun", sInfo);
	}
	if(g_hItemCosts[CostChrome].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Chrome Shotgun", client);
		menu.AddItem("weapon_shotgun_chrome", sInfo);
	}
	if(g_hItemCosts[CostSPAS].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "SPAS Shotgun", client);
		menu.AddItem("weapon_shotgun_spas", sInfo);
	}
	if(g_hItemCosts[CostPump].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Pump Shotgun", client);
		menu.AddItem("weapon_pumpshotgun", sInfo);
	}
	FormatEx(sInfo, sizeof(sInfo),"%T", "Points Left", client, g_esPlayerData[client].iPlayerPoints);
	menu.SetTitle(sInfo);
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

void BuildSMGMenu(int client)
{
	char sInfo[32];
	Menu menu = new Menu(MenuHandler_SMG);
	if(g_hItemCosts[CostUzi].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Uzi", client);
		menu.AddItem("weapon_smg", sInfo);
	}
	if(g_hItemCosts[CostSilenced].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Silenced SMG", client);
		menu.AddItem("weapon_smg_silenced", sInfo);
	}
	if(g_hItemCosts[CostMP5].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "MP5 SMG", client);
		menu.AddItem("weapon_smg_mp5", sInfo);
	}
	FormatEx(sInfo, sizeof(sInfo),"%T", "Points Left", client, g_esPlayerData[client].iPlayerPoints);
	menu.SetTitle(sInfo);
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

void BuildHealthMenu(int client)
{
	char sInfo[32];
	Menu menu = new Menu(MenuHandler_Health);
	if(g_hItemCosts[CostHealthKit].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "First Aid Kit", client);
		menu.AddItem("weapon_first_aid_kit", sInfo);
	}
	if(g_hItemCosts[CostDefib].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Defibrillator", client);
		menu.AddItem("weapon_defibrillator", sInfo);
	}
	if(g_hItemCosts[CostPills].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Pills", client);
		menu.AddItem("weapon_pain_pills", sInfo);
	}
	if(g_hItemCosts[CostAdren].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Adrenaline", client);
		menu.AddItem("weapon_adrenaline", sInfo);
	}
	if(g_hItemCosts[CostHeal].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Full Heal", client);
		menu.AddItem("health", sInfo);
	}
	FormatEx(sInfo, sizeof(sInfo),"%T", "Points Left", client, g_esPlayerData[client].iPlayerPoints);
	menu.SetTitle(sInfo);
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

void BuildThrowablesMenu(int client)
{
	char sInfo[32];
	Menu menu = new Menu(MenuHandler_Throwables);
	if(g_hItemCosts[CostMolotov].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Molotov", client);
		menu.AddItem("weapon_molotov", sInfo);
	}
	if(g_hItemCosts[CostPipe].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Pipe Bomb", client);
		menu.AddItem("weapon_pipe_bomb", sInfo);
	}
	if(g_hItemCosts[CostBile].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Bile Bomb", client);
		menu.AddItem("weapon_vomitjar", sInfo);
	}
	FormatEx(sInfo, sizeof(sInfo),"%T", "Points Left", client, g_esPlayerData[client].iPlayerPoints);
	menu.SetTitle(sInfo);
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

void BuildMiscMenu(int client)
{
	char sInfo[32];
	Menu menu = new Menu(MenuHandler_Misc);
	if(g_hItemCosts[CostGrenade].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Grenade Launcher", client);
		menu.AddItem("weapon_grenade_launcher", sInfo);
	}
	if(g_hItemCosts[CostP220].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "P220 Pistol", client);
		menu.AddItem("weapon_pistol", sInfo);
	}
	if(g_hItemCosts[CostMagnum].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Magnum Pistol", client);
		menu.AddItem("weapon_pistol_magnum", sInfo);
	}
	if(g_hItemCosts[CostChainsaw].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Chainsaw", client);
		menu.AddItem("weapon_chainsaw", sInfo);
	}
	if(g_hItemCosts[CostGnome].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Gnome", client);
		menu.AddItem("weapon_gnome", sInfo);
	}
	if(strcmp(g_sCurrentMap, "c1m2_streets", false) != 0 && g_hItemCosts[CostCola].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Cola Bottles", client);
		menu.AddItem("weapon_cola_bottles", sInfo);
	}
	if(g_hItemCosts[CostFireworks].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Fireworks Crate", client);
		menu.AddItem("weapon_fireworkcrate", sInfo);
	}
	if(strcmp(g_sGameMode, "scavenge", false) != 0 && g_hItemCosts[CostGasCan].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Gascan", client);
		menu.AddItem("weapon_gascan", sInfo);
	}
	if(g_hItemCosts[CostOxygen].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Oxygen Tank", client);
		menu.AddItem("weapon_oxygentank", sInfo);
	}
	if(g_hItemCosts[CostPropane].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Propane Tank", client);
		menu.AddItem("weapon_propanetank", sInfo);
	}
	FormatEx(sInfo, sizeof(sInfo),"%T", "Points Left", client, g_esPlayerData[client].iPlayerPoints);
	menu.SetTitle(sInfo);
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

void BuildUpgradesMenu(int client)
{
	char sInfo[32];
	Menu menu = new Menu(MenuHandler_Upgrades);
	if(g_hItemCosts[CostLaserSight].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Laser Sight", client);
		menu.AddItem("laser_sight", sInfo);
	}
	if(g_hItemCosts[CostExplosiveAmmo].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Explosive Ammo", client);
		menu.AddItem("explosive_ammo", sInfo);
	}
	if(g_hItemCosts[CostFireAmmo].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Incendiary Ammo", client);
		menu.AddItem("incendiary_ammo", sInfo);
	}
	if(g_hItemCosts[CostExplosivePack].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Explosive Ammo Pack", client);
		menu.AddItem("upgradepack_explosive", sInfo);
	}
	if(g_hItemCosts[CostFirePack].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Incendiary Ammo Pack", client);
		menu.AddItem("upgradepack_incendiary", sInfo);
	}
	if(g_hItemCosts[CostAmmo].IntValue > -1)
	{
		FormatEx(sInfo, sizeof(sInfo), "%T", "Ammo", client);
		menu.AddItem("ammo", sInfo);
	}
	FormatEx(sInfo, sizeof(sInfo),"%T", "Points Left", client, g_esPlayerData[client].iPlayerPoints);
	menu.SetTitle(sInfo);
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Melee(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[32];
			menu.GetItem(param2, sItem, sizeof(sItem));
			FormatEx(g_esPlayerData[param1].sItemName, 64, "give %s", sItem);
			int sequence = GetMeleeCost(sItem);
			if(sequence != -1)
				g_esPlayerData[param1].iItemCost = g_hItemCosts[sequence + 25].IntValue;
			else
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostCustomMelee].IntValue;
			DisplayConfirmMenuMelee(param1);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				BuildWeaponsMenu(param1);
		}
		case MenuAction_End:
			delete menu;
	}
}

public int MenuHandler_SMG(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[32];
			menu.GetItem(param2, sItem, sizeof(sItem));
			if(!strcmp(sItem, "weapon_smg", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give smg");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostUzi].IntValue;
			}
			else if(!strcmp(sItem, "weapon_smg_silenced", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give smg_silenced");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostSilenced].IntValue;
			}
			else if(!strcmp(sItem, "weapon_smg_mp5", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give smg_mp5");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostMP5].IntValue;
			}
			DisplayConfirmMenuSMG(param1);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				BuildWeaponsMenu(param1);
		}
		case MenuAction_End:
			delete menu;
	}
}

public int MenuHandler_Rifles(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[32];
			menu.GetItem(param2, sItem, sizeof(sItem));
			if(!strcmp(sItem, "weapon_rifle", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give weapon_rifle");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostM16].IntValue;
			}
			else if(!strcmp(sItem, "weapon_rifle_desert", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give rifle_desert");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostSCAR].IntValue;
			}
			else if(!strcmp(sItem, "weapon_rifle_ak47", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give rifle_ak47");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostAK47].IntValue;
			}
			else if(!strcmp(sItem, "weapon_rifle_sg552", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give rifle_sg552");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostSG552].IntValue;
			}
			else if(!strcmp(sItem, "weapon_rifle_m60", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give rifle_m60");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostM60].IntValue;
			}
			DisplayConfirmMenuRifles(param1);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				BuildWeaponsMenu(param1);
		}
		case MenuAction_End:
			delete menu;
	}
}

public int MenuHandler_Snipers(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[32];
			menu.GetItem(param2, sItem, sizeof(sItem));
			if(!strcmp(sItem, "weapon_hunting_rifle", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give hunting_rifle");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostHunting].IntValue;
			}
			else if(!strcmp(sItem, "weapon_sniper_scout", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give sniper_scout");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostScout].IntValue;
			}
			else if(!strcmp(sItem, "weapon_sniper_awp", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give sniper_awp");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostAWP].IntValue;
			}
			else if(!strcmp(sItem, "weapon_sniper_military", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give sniper_military");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostMilitary].IntValue;
			}
			DisplayConfirmMenuSnipers(param1);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				BuildWeaponsMenu(param1);
		}
		case MenuAction_End:
			delete menu;
	}
}

public int MenuHandler_Shotguns(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[32];
			menu.GetItem(param2, sItem, sizeof(sItem));
			if(!strcmp(sItem, "weapon_shotgun_chrome", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give shotgun_chrome");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostChrome].IntValue;
			}
			else if(!strcmp(sItem, "weapon_pumpshotgun", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give pumpshotgun");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostPump].IntValue;
			}
			else if(!strcmp(sItem, "weapon_autoshotgun", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give autoshotgun");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostAuto].IntValue;
			}
			else if(!strcmp(sItem, "weapon_shotgun_spas", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give shotgun_spas");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostSPAS].IntValue;
			}
			DisplayConfirmMenuShotguns(param1);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				BuildWeaponsMenu(param1);
		}
		case MenuAction_End:
			delete menu;
	}
}

public int MenuHandler_Throwables(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[32];
			menu.GetItem(param2, sItem, sizeof(sItem));
			if(!strcmp(sItem, "weapon_molotov", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give molotov");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostMolotov].IntValue;
			}
			else if(!strcmp(sItem, "weapon_pipe_bomb", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give pipe_bomb");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostPipe].IntValue;
			}
			else if(!strcmp(sItem, "weapon_vomitjar", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give vomitjar");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostBile].IntValue;
			}
			DisplayConfirmMenuThrow(param1);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				BuildWeaponsMenu(param1);
		}
		case MenuAction_End:
			delete menu;
	}
}

public int MenuHandler_Misc(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[32];
			menu.GetItem(param2, sItem, sizeof(sItem));
			if(!strcmp(sItem, "weapon_pistol", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give pistol");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostP220].IntValue;
			}
			else if(!strcmp(sItem, "weapon_pistol_magnum", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give pistol_magnum");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostMagnum].IntValue;
			}
			else if(!strcmp(sItem, "weapon_grenade_launcher", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give grenade_launcher");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostGrenade].IntValue;
			}
			else if(!strcmp(sItem, "weapon_chainsaw", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give chainsaw");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostChainsaw].IntValue;
			}
			else if(!strcmp(sItem, "weapon_gnome", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give gnome");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostGnome].IntValue;
			}
			else if(!strcmp(sItem, "weapon_cola_bottles", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give cola_bottles");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostCola].IntValue;
			}
			else if(!strcmp(sItem, "weapon_gascan", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give gascan");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostGasCan].IntValue;
			}
			else if(!strcmp(sItem, "weapon_propanetank", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give propanetank");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostPropane].IntValue;
			}
			else if(!strcmp(sItem, "weapon_fireworkcrate", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give fireworkcrate");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostFireworks].IntValue;
			}
			else if(!strcmp(sItem, "weapon_oxygentank", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give oxygentank");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostOxygen].IntValue;
			}
			DisplayConfirmMenuMisc(param1);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				BuildWeaponsMenu(param1);
		}
		case MenuAction_End:
			delete menu;
	}
}

public int MenuHandler_Health(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[32];
			menu.GetItem(param2, sItem, sizeof(sItem));
			if(!strcmp(sItem, "weapon_first_aid_kit", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give first_aid_kit");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostHealthKit].IntValue;
			}
			else if(!strcmp(sItem, "weapon_defibrillator", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give defibrillator");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostDefib].IntValue;
			}
			else if(!strcmp(sItem, "weapon_pain_pills", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give pain_pills");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostPills].IntValue;
			}
			else if(!strcmp(sItem, "weapon_adrenaline", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give adrenaline");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostAdren].IntValue;
			}
			else if(!strcmp(sItem, "health", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give health");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostHeal].IntValue;
			}
			DisplayConfirmMenuHealth(param1);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				BuildBuyMenu(param1);
		}
		case MenuAction_End:
			delete menu;
	}
}

public int MenuHandler_Upgrades(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[32];
			menu.GetItem(param2, sItem, sizeof(sItem));
			if(!strcmp(sItem, "upgradepack_explosive", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give upgradepack_explosive");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostExplosivePack].IntValue;
			}
			else if(!strcmp(sItem, "upgradepack_incendiary", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give upgradepack_incendiary");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostFirePack].IntValue;
			}
			else if(!strcmp(sItem, "explosive_ammo", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "upgrade_add EXPLOSIVE_AMMO");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostExplosiveAmmo].IntValue;
			}
			else if(!strcmp(sItem, "incendiary_ammo", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "upgrade_add INCENDIARY_AMMO");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostFireAmmo].IntValue;
			}
			else if(!strcmp(sItem, "laser_sight", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "upgrade_add LASER_SIGHT");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostLaserSight].IntValue;
			}
			else if(!strcmp(sItem, "ammo", false))
			{
				strcopy(g_esPlayerData[param1].sItemName, 64, "give ammo");
				g_esPlayerData[param1].iItemCost = g_hItemCosts[CostAmmo].IntValue;
			}
			DisplayConfirmMenuUpgrades(param1);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				BuildBuyMenu(param1);
		}
		case MenuAction_End:
			delete menu;
	}
}

public int InfectedMenu(Menu menu, MenuAction action, int client, int iPosition)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[32];
			menu.GetItem(iPosition, sItem, sizeof(sItem));
			if(!strcmp(sItem, "heal", false))
			{
				strcopy(g_esPlayerData[client].sItemName, 64, "give health");
				if(IsTank(client))
					g_esPlayerData[client].iItemCost = g_hItemCosts[CostInfectedHeal].IntValue * g_hItemCosts[CostTankHealMultiplier].IntValue;
				else
					g_esPlayerData[client].iItemCost = g_hItemCosts[CostInfectedHeal].IntValue;
			}
			else if(!strcmp(sItem, "suicide", false))
			{
				strcopy(g_esPlayerData[client].sItemName, 64, "suicide");
				g_esPlayerData[client].iItemCost = g_hItemCosts[CostSuicide].IntValue;
			}
			else if(!strcmp(sItem, "boomer", false))
			{
				strcopy(g_esPlayerData[client].sItemName, 64, "z_spawn_old boomer");
				g_esPlayerData[client].iItemCost = g_hItemCosts[CostBoomer].IntValue;
			}
			else if(!strcmp(sItem, "spitter", false))
			{
				strcopy(g_esPlayerData[client].sItemName, 64, "z_spawn_old spitter");
				g_esPlayerData[client].iItemCost = g_hItemCosts[CostSpitter].IntValue;
			}
			else if(!strcmp(sItem, "smoker", false))
			{
				strcopy(g_esPlayerData[client].sItemName, 64, "z_spawn_old smoker");
				g_esPlayerData[client].iItemCost = g_hItemCosts[CostSmoker].IntValue;
			}
			else if(!strcmp(sItem, "hunter", false))
			{
				strcopy(g_esPlayerData[client].sItemName, 64, "z_spawn_old hunter");
				g_esPlayerData[client].iItemCost = g_hItemCosts[CostHunter].IntValue;
			}
			else if(!strcmp(sItem, "charger", false))
			{
				strcopy(g_esPlayerData[client].sItemName, 64, "z_spawn_old charger");
				g_esPlayerData[client].iItemCost = g_hItemCosts[CostCharger].IntValue;
			}
			else if(!strcmp(sItem, "jockey", false))
			{
				strcopy(g_esPlayerData[client].sItemName, 64, "z_spawn_old jockey");
				g_esPlayerData[client].iItemCost = g_hItemCosts[CostJockey].IntValue;
			}
			else if(!strcmp(sItem, "witch", false))
			{
				strcopy(g_esPlayerData[client].sItemName, 64, "z_spawn_old witch");
				g_esPlayerData[client].iItemCost = g_hItemCosts[CostWitch].IntValue;
			}
			else if(!strcmp(sItem, "witch_bride", false))
			{
				strcopy(g_esPlayerData[client].sItemName, 64, "z_spawn_old witch_bride");
				g_esPlayerData[client].iItemCost = g_hItemCosts[CostWitch].IntValue;
			}
			else if(!strcmp(sItem, "tank", false))
			{
				strcopy(g_esPlayerData[client].sItemName, 64, "z_spawn_old tank");
				g_esPlayerData[client].iItemCost = g_hItemCosts[CostTank].IntValue;
			}
			else if(!strcmp(sItem, "horde", false))
			{
				strcopy(g_esPlayerData[client].sItemName, 64, "director_force_panic_event");
				g_esPlayerData[client].iItemCost = g_hItemCosts[CostHorde].IntValue;
			}
			else if(!strcmp(sItem, "mob", false))
			{
				strcopy(g_esPlayerData[client].sItemName, 64, "z_spawn_old mob");
				g_esPlayerData[client].iItemCost = g_hItemCosts[CostMob].IntValue;
			}
			else if(!strcmp(sItem, "uncommon_mob", false))
			{
				strcopy(g_esPlayerData[client].sItemName, 64, "z_spawn_old mob");
				g_esPlayerData[client].iItemCost = g_hItemCosts[CostUncommonMob].IntValue;
			}
			DisplayConfirmMenuI(client);
		}
		case MenuAction_End:
			delete menu;
	}
}

public void OnEntityCreated(int entity, const char[] classPlayerName)
{
	if(!strcmp(classPlayerName, "infected", false) && CounterData[iUCommonLeft] > 0)
	{
		switch(GetRandomInt(1, 6))
		{
			case 1:
				SetEntityModel(entity, "models/infected/common_male_riot.mdl");

			case 2:
				SetEntityModel(entity, "models/infected/common_male_ceda.mdl");

			case 3:
				SetEntityModel(entity, "models/infected/common_male_clown.mdl");

			case 4:
				SetEntityModel(entity, "models/infected/common_male_mud.mdl");

			case 5:
				SetEntityModel(entity, "models/infected/common_male_roadcrew.mdl");

			case 6:
				SetEntityModel(entity, "models/infected/common_male_fallen_survivor.mdl");
		}
		CounterData[iUCommonLeft]--;
	}
}

void DisplayConfirmMenuMelee(int param1)
{
	char sInfo[32];
	Menu menu = new Menu(MenuHandler_ConfirmMelee);
	FormatEx(sInfo, sizeof(sInfo),"%T", "Yes", param1);
	menu.AddItem("yes", sInfo);
	FormatEx(sInfo, sizeof(sInfo),"%T", "No", param1);
	menu.AddItem("no", sInfo);
	FormatEx(sInfo, sizeof(sInfo),"%T", "Cost", param1, g_esPlayerData[param1].iItemCost);
	menu.SetTitle(sInfo);
	menu.ExitBackButton = true;
	menu.Display(param1, MENU_TIME_FOREVER);
}

void DisplayConfirmMenuSMG(int param1)
{
	char sInfo[32];
	Menu menu = new Menu(MenuHandler_ConfirmSMG);
	FormatEx(sInfo, sizeof(sInfo),"%T", "Yes", param1);
	menu.AddItem("yes", sInfo);
	FormatEx(sInfo, sizeof(sInfo),"%T", "No", param1);
	menu.AddItem("no", sInfo);
	FormatEx(sInfo, sizeof(sInfo),"%T", "Cost", param1, g_esPlayerData[param1].iItemCost);
	menu.SetTitle(sInfo);
	menu.ExitBackButton = true;
	menu.Display(param1, MENU_TIME_FOREVER);
}

void DisplayConfirmMenuRifles(int param1)
{
	char sInfo[32];
	Menu menu = new Menu(MenuHandler_ConfirmRifles);
	FormatEx(sInfo, sizeof(sInfo),"%T", "Yes", param1);
	menu.AddItem("yes", sInfo);
	FormatEx(sInfo, sizeof(sInfo),"%T", "No", param1);
	menu.AddItem("no", sInfo);
	FormatEx(sInfo, sizeof(sInfo),"%T", "Cost", param1, g_esPlayerData[param1].iItemCost);
	menu.SetTitle(sInfo);
	menu.ExitBackButton = true;
	menu.Display(param1, MENU_TIME_FOREVER);
}

void DisplayConfirmMenuSnipers(int param1)
{
	char sInfo[32];
	Menu menu = new Menu(MenuHandler_ConfirmSniper);
	FormatEx(sInfo, sizeof(sInfo),"%T", "Yes", param1);
	menu.AddItem("yes", sInfo);
	FormatEx(sInfo, sizeof(sInfo),"%T", "No", param1);
	menu.AddItem("no", sInfo);
	FormatEx(sInfo, sizeof(sInfo),"%T", "Cost", param1, g_esPlayerData[param1].iItemCost);
	menu.SetTitle(sInfo);
	menu.ExitBackButton = true;
	menu.Display(param1, MENU_TIME_FOREVER);
}

void DisplayConfirmMenuShotguns(int param1)
{
	char sInfo[32];
	Menu menu = new Menu(MenuHandler_ConfirmShotguns);
	FormatEx(sInfo, sizeof(sInfo),"%T", "Yes", param1);
	menu.AddItem("yes", sInfo);
	FormatEx(sInfo, sizeof(sInfo),"%T", "No", param1);
	menu.AddItem("no", sInfo);
	FormatEx(sInfo, sizeof(sInfo),"%T", "Cost", param1, g_esPlayerData[param1].iItemCost);
	menu.SetTitle(sInfo);
	menu.ExitBackButton = true;
	menu.Display(param1, MENU_TIME_FOREVER);
}

void DisplayConfirmMenuThrow(int param1)
{
	char sInfo[32];
	Menu menu = new Menu(MenuHandler_ConfirmThrow);
	FormatEx(sInfo, sizeof(sInfo),"%T", "Yes", param1);
	menu.AddItem("yes", sInfo);
	FormatEx(sInfo, sizeof(sInfo),"%T", "No", param1);
	menu.AddItem("no", sInfo);
	FormatEx(sInfo, sizeof(sInfo),"%T", "Cost", param1, g_esPlayerData[param1].iItemCost);
	menu.SetTitle(sInfo);
	menu.ExitBackButton = true;
	menu.Display(param1, MENU_TIME_FOREVER);
}

void DisplayConfirmMenuMisc(int param1)
{
	char sInfo[32];
	Menu menu = new Menu(MenuHandler_ConfirmMisc);
	FormatEx(sInfo, sizeof(sInfo),"%T", "Yes", param1);
	menu.AddItem("yes", sInfo);
	FormatEx(sInfo, sizeof(sInfo),"%T", "No", param1);
	menu.AddItem("no", sInfo);
	FormatEx(sInfo, sizeof(sInfo),"%T", "Cost", param1, g_esPlayerData[param1].iItemCost);
	menu.SetTitle(sInfo);
	menu.ExitBackButton = true;
	menu.Display(param1, MENU_TIME_FOREVER);
}

void DisplayConfirmMenuHealth(int param1)
{
	char sInfo[32];
	Menu menu = new Menu(MenuHandler_ConfirmHealth);
	FormatEx(sInfo, sizeof(sInfo),"%T", "Yes", param1);
	menu.AddItem("yes", sInfo);
	FormatEx(sInfo, sizeof(sInfo),"%T", "No", param1);
	menu.AddItem("no", sInfo);
	FormatEx(sInfo, sizeof(sInfo),"%T", "Cost", param1, g_esPlayerData[param1].iItemCost);
	menu.SetTitle(sInfo);
	menu.ExitBackButton = true;
	menu.Display(param1, MENU_TIME_FOREVER);
}

void DisplayConfirmMenuUpgrades(int param1)
{
	char sInfo[32];
	Menu menu = new Menu(MenuHandler_ConfirmUpgrades);
	FormatEx(sInfo, sizeof(sInfo),"%T", "Yes", param1);
	menu.AddItem("yes", sInfo);
	FormatEx(sInfo, sizeof(sInfo),"%T", "No", param1);
	menu.AddItem("no", sInfo);
	FormatEx(sInfo, sizeof(sInfo),"%T", "Cost", param1, g_esPlayerData[param1].iItemCost);
	menu.SetTitle(sInfo);
	menu.ExitBackButton = true;
	menu.Display(param1, MENU_TIME_FOREVER);
}

void DisplayConfirmMenuI(int param1)
{
	char sInfo[32];
	Menu menu = new Menu(MenuHandler_ConfirmI);
	FormatEx(sInfo, sizeof(sInfo),"%T", "Yes", param1);
	menu.AddItem("yes", sInfo);
	FormatEx(sInfo, sizeof(sInfo),"%T", "No", param1);
	menu.AddItem("no", sInfo);
	FormatEx(sInfo, sizeof(sInfo),"%T", "Cost", param1, g_esPlayerData[param1].iItemCost);
	menu.SetTitle(sInfo);
	menu.ExitBackButton = true;
	menu.Display(param1, MENU_TIME_FOREVER);
}

public int MenuHandler_ConfirmMelee(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[32];
			menu.GetItem(param2, sItem, sizeof(sItem));
			if(strcmp(sItem, "no", false) == 0)
			{
				BuildMeleeMenu(param1);
				strcopy(g_esPlayerData[param1].sItemName, 64, g_esPlayerData[param1].sBought);
				g_esPlayerData[param1].iItemCost = g_esPlayerData[param1].iBoughtCost;
			}
			else if(strcmp(sItem, "yes", false) == 0)
			{
				if(HasEnoughPoints(param1, g_esPlayerData[param1].iItemCost))
				{
					strcopy(g_esPlayerData[param1].sBought, 64, g_esPlayerData[param1].sItemName);
					g_esPlayerData[param1].iBoughtCost = g_esPlayerData[param1].iItemCost;
					RemovePoints(param1, g_esPlayerData[param1].iItemCost);
					CheatCommand(param1, g_esPlayerData[param1].sItemName);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				BuildMeleeMenu(param1);

			strcopy(g_esPlayerData[param1].sItemName, 64, g_esPlayerData[param1].sBought);
			g_esPlayerData[param1].iItemCost = g_esPlayerData[param1].iBoughtCost;
		}
		case MenuAction_End:
			delete menu;
	}
}

public int MenuHandler_ConfirmRifles(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[32];
			menu.GetItem(param2, sItem, sizeof(sItem));
			if(strcmp(sItem, "no", false) == 0)
			{
				BuildRiflesMenu(param1);
				strcopy(g_esPlayerData[param1].sItemName, 64, g_esPlayerData[param1].sBought);
				g_esPlayerData[param1].iItemCost = g_esPlayerData[param1].iBoughtCost;
			}
			else if(strcmp(sItem, "yes", false) == 0)
			{
				if(HasEnoughPoints(param1, g_esPlayerData[param1].iItemCost))
				{
					strcopy(g_esPlayerData[param1].sBought, 64, g_esPlayerData[param1].sItemName);
					g_esPlayerData[param1].iBoughtCost = g_esPlayerData[param1].iItemCost;
					RemovePoints(param1, g_esPlayerData[param1].iItemCost);
					CheatCommand(param1, g_esPlayerData[param1].sItemName);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				BuildRiflesMenu(param1);

			strcopy(g_esPlayerData[param1].sItemName, 64, g_esPlayerData[param1].sBought);
			g_esPlayerData[param1].iItemCost = g_esPlayerData[param1].iBoughtCost;
		}
		case MenuAction_End:
			delete menu;
	}
}

public int MenuHandler_ConfirmSniper(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[32];
			menu.GetItem(param2, sItem, sizeof(sItem));
			if(strcmp(sItem, "no", false) == 0)
			{
				BuildSniperMenu(param1);
				strcopy(g_esPlayerData[param1].sItemName, 64, g_esPlayerData[param1].sBought);
				g_esPlayerData[param1].iItemCost = g_esPlayerData[param1].iBoughtCost;
			}
			else if(strcmp(sItem, "yes", false) == 0)
			{
				if(HasEnoughPoints(param1, g_esPlayerData[param1].iItemCost))
				{
					strcopy(g_esPlayerData[param1].sBought, 64, g_esPlayerData[param1].sItemName);
					g_esPlayerData[param1].iBoughtCost = g_esPlayerData[param1].iItemCost;
					RemovePoints(param1, g_esPlayerData[param1].iItemCost);
					CheatCommand(param1, g_esPlayerData[param1].sItemName);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				BuildSniperMenu(param1);

			strcopy(g_esPlayerData[param1].sItemName, 64, g_esPlayerData[param1].sBought);
			g_esPlayerData[param1].iItemCost = g_esPlayerData[param1].iBoughtCost;
		}
		case MenuAction_End:
			delete menu;
	}
}

public int MenuHandler_ConfirmSMG(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[32];
			menu.GetItem(param2, sItem, sizeof(sItem));
			if(strcmp(sItem, "no", false) == 0)
			{
				BuildSMGMenu(param1);
				strcopy(g_esPlayerData[param1].sItemName, 64, g_esPlayerData[param1].sBought);
				g_esPlayerData[param1].iItemCost = g_esPlayerData[param1].iBoughtCost;
			}
			else if(strcmp(sItem, "yes", false) == 0)
			{
				if(HasEnoughPoints(param1, g_esPlayerData[param1].iItemCost))
				{
					strcopy(g_esPlayerData[param1].sBought, 64, g_esPlayerData[param1].sItemName);
					g_esPlayerData[param1].iBoughtCost = g_esPlayerData[param1].iItemCost;
					RemovePoints(param1, g_esPlayerData[param1].iItemCost);
					CheatCommand(param1, g_esPlayerData[param1].sItemName);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				BuildSMGMenu(param1);

			strcopy(g_esPlayerData[param1].sItemName, 64, g_esPlayerData[param1].sBought);
			g_esPlayerData[param1].iItemCost = g_esPlayerData[param1].iBoughtCost;
		}
		case MenuAction_End:
			delete menu;
	}
}

public int MenuHandler_ConfirmShotguns(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[32];
			menu.GetItem(param2, sItem, sizeof(sItem));
			if(strcmp(sItem, "no", false) == 0)
			{
				BuildShotgunMenu(param1);
				strcopy(g_esPlayerData[param1].sItemName, 64, g_esPlayerData[param1].sBought);
				g_esPlayerData[param1].iItemCost = g_esPlayerData[param1].iBoughtCost;
			}
			else if(strcmp(sItem, "yes", false) == 0)
			{
				if(HasEnoughPoints(param1, g_esPlayerData[param1].iItemCost))
				{
					strcopy(g_esPlayerData[param1].sBought, 64, g_esPlayerData[param1].sItemName);
					g_esPlayerData[param1].iBoughtCost = g_esPlayerData[param1].iItemCost;
					RemovePoints(param1, g_esPlayerData[param1].iItemCost);
					CheatCommand(param1, g_esPlayerData[param1].sItemName);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				BuildShotgunMenu(param1);

			strcopy(g_esPlayerData[param1].sItemName, 64, g_esPlayerData[param1].sBought);
			g_esPlayerData[param1].iItemCost = g_esPlayerData[param1].iBoughtCost;
		}
		case MenuAction_End:
			delete menu;
	}
}

public int MenuHandler_ConfirmThrow(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[32];
			menu.GetItem(param2, sItem, sizeof(sItem));
			if(strcmp(sItem, "no", false) == 0)
			{
				BuildThrowablesMenu(param1);
				strcopy(g_esPlayerData[param1].sItemName, 64, g_esPlayerData[param1].sBought);
				g_esPlayerData[param1].iItemCost = g_esPlayerData[param1].iBoughtCost;
			}
			else if(strcmp(sItem, "yes", false) == 0)
			{
				if(HasEnoughPoints(param1, g_esPlayerData[param1].iItemCost))
				{
					strcopy(g_esPlayerData[param1].sBought, 64, g_esPlayerData[param1].sItemName);
					g_esPlayerData[param1].iBoughtCost = g_esPlayerData[param1].iItemCost;
					RemovePoints(param1, g_esPlayerData[param1].iItemCost);
					CheatCommand(param1, g_esPlayerData[param1].sItemName);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				BuildThrowablesMenu(param1);

			strcopy(g_esPlayerData[param1].sItemName, 64, g_esPlayerData[param1].sBought);
			g_esPlayerData[param1].iItemCost = g_esPlayerData[param1].iBoughtCost;
		}
		case MenuAction_End:
			delete menu;
	}
}

public int MenuHandler_ConfirmMisc(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[32];
			menu.GetItem(param2, sItem, sizeof(sItem));
			if(strcmp(sItem, "no", false) == 0)
			{
				BuildMiscMenu(param1);
				strcopy(g_esPlayerData[param1].sItemName, 64, g_esPlayerData[param1].sBought);
				g_esPlayerData[param1].iItemCost = g_esPlayerData[param1].iBoughtCost;
			}
			else if(strcmp(sItem, "yes", false) == 0)
			{
				if(HasEnoughPoints(param1, g_esPlayerData[param1].iItemCost))
				{
					strcopy(g_esPlayerData[param1].sBought, 64, g_esPlayerData[param1].sItemName);
					g_esPlayerData[param1].iBoughtCost = g_esPlayerData[param1].iItemCost;
					RemovePoints(param1, g_esPlayerData[param1].iItemCost);
					CheatCommand(param1, g_esPlayerData[param1].sItemName);
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				BuildMiscMenu(param1);

			strcopy(g_esPlayerData[param1].sItemName, 64, g_esPlayerData[param1].sBought);
			g_esPlayerData[param1].iItemCost = g_esPlayerData[param1].iBoughtCost;
		}
		case MenuAction_End:
			delete menu;
	}
}

public int MenuHandler_ConfirmHealth(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[32];
			menu.GetItem(param2, sItem, sizeof(sItem));
			if(strcmp(sItem, "no", false) == 0)
			{
				BuildHealthMenu(param1);
				strcopy(g_esPlayerData[param1].sItemName, 64, g_esPlayerData[param1].sBought);
				g_esPlayerData[param1].iItemCost = g_esPlayerData[param1].iBoughtCost;
			}
			else if(strcmp(sItem, "yes", false) == 0)
			{
				if(HasEnoughPoints(param1, g_esPlayerData[param1].iItemCost))
				{
					if(!strcmp(g_esPlayerData[param1].sItemName, "give health", false))
					{
						strcopy(g_esPlayerData[param1].sBought, 64, g_esPlayerData[param1].sItemName);
						g_esPlayerData[param1].iBoughtCost = g_esPlayerData[param1].iItemCost;
						RemovePoints(param1, g_esPlayerData[param1].iItemCost);
						CheatCommand(param1, g_esPlayerData[param1].sItemName);
					}
					else
					{
						strcopy(g_esPlayerData[param1].sBought, 64, g_esPlayerData[param1].sItemName);
						g_esPlayerData[param1].iBoughtCost = g_esPlayerData[param1].iItemCost;
						RemovePoints(param1, g_esPlayerData[param1].iItemCost);
						CheatCommand(param1, g_esPlayerData[param1].sItemName);
					}
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				BuildHealthMenu(param1);

			strcopy(g_esPlayerData[param1].sItemName, 64, g_esPlayerData[param1].sBought);
			g_esPlayerData[param1].iItemCost = g_esPlayerData[param1].iBoughtCost;
		}
		case MenuAction_End:
			delete menu;
	}
}

void ReloadAmmo(int client, int iCost, const char[] sItem)
{
	int iWeapon = GetPlayerWeaponSlot(client, 0);
	if(iWeapon > MaxClients && IsValidEntity(iWeapon))
	{

		char sWeapon[32];
		GetEdictClassname(iWeapon, sWeapon, sizeof(sWeapon));
		if(strcmp(sWeapon, "weapon_rifle_m60") == 0)
		{
			if(g_iClipSize_RifleM60 <= 0)
				g_iClipSize_RifleM60 = 150;

			SetEntProp(iWeapon, Prop_Send, "m_iClip1", g_iClipSize_RifleM60);
		}
		else if(strcmp(sWeapon, "weapon_grenade_launcher") == 0)
		{
			if(g_iClipSize_GrenadeLauncher <= 0)
				g_iClipSize_GrenadeLauncher = 1;
			
			SetEntProp(iWeapon, Prop_Send, "m_iClip1", g_iClipSize_GrenadeLauncher);

			int iAmmo_Max = FindConVar("ammo_grenadelauncher_max").IntValue;
			if(iAmmo_Max <= 0)
				iAmmo_Max = 30;

			SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_iAmmo") + 68, iAmmo_Max);
		}
		CheatCommand(client, sItem);
		RemovePoints(client, iCost);
	}
	else
		PrintToChat(client, "%s %T", MSGTAG, "Primary Warning", client);
}

public int MenuHandler_ConfirmUpgrades(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[32];
			menu.GetItem(param2, sItem, sizeof(sItem));
			if(strcmp(sItem, "no", false) == 0)
			{
				BuildUpgradesMenu(param1);
				strcopy(g_esPlayerData[param1].sItemName, 64, g_esPlayerData[param1].sBought);
				g_esPlayerData[param1].iItemCost = g_esPlayerData[param1].iBoughtCost;
			}
			else if(strcmp(sItem, "yes", false) == 0)
			{
				if(HasEnoughPoints(param1, g_esPlayerData[param1].iItemCost)){
					if(!strcmp(g_esPlayerData[param1].sItemName, "give ammo", false))
						ReloadAmmo(param1, g_esPlayerData[param1].iItemCost, g_esPlayerData[param1].sItemName);
					else
					{
						strcopy(g_esPlayerData[param1].sBought, 64, g_esPlayerData[param1].sItemName);
						g_esPlayerData[param1].iBoughtCost = g_esPlayerData[param1].iItemCost;
						RemovePoints(param1, g_esPlayerData[param1].iItemCost);
						CheatCommand(param1, g_esPlayerData[param1].sItemName);
					}
				}
			}
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				BuildUpgradesMenu(param1);

			strcopy(g_esPlayerData[param1].sItemName, 64, g_esPlayerData[param1].sBought);
			g_esPlayerData[param1].iItemCost = g_esPlayerData[param1].iBoughtCost;
		}
		case MenuAction_End:
			delete menu;
	}
}

public int MenuHandler_ConfirmI(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[32];
			menu.GetItem(param2, sItem, sizeof(sItem));
			if(strcmp(sItem, "no", false) == 0)
			{
				BuildBuyMenu(param1);
				strcopy(g_esPlayerData[param1].sItemName, 64, g_esPlayerData[param1].sBought);
				g_esPlayerData[param1].iItemCost = g_esPlayerData[param1].iBoughtCost;
			}
			else if(strcmp(sItem, "yes", false) == 0)
			{
				if(!HasEnoughPoints(param1, g_esPlayerData[param1].iItemCost))
					return;

				if(!strcmp(g_esPlayerData[param1].sItemName, "suicide", false))
					PerformSuicide(param1, g_esPlayerData[param1].iItemCost);
				else if(!strcmp(g_esPlayerData[param1].sItemName, "z_spawn_old mob", false))
					CounterData[iUCommonLeft] += FindConVar("z_common_limit").IntValue;
				else if(!strcmp(g_esPlayerData[param1].sItemName, "z_spawn_old tank", false))
				{
					if(CounterData[iTanksSpawned] == PluginSettings[hTankLimit].IntValue)
						PrintToChat(param1,  "%T", "Tank Limit", param1);
					else
						CounterData[iWitchesSpawned]++;
				}
				else if(!strcmp(g_esPlayerData[param1].sItemName, "z_spawn_old witch", false) || !strcmp(g_esPlayerData[param1].sItemName, "z_spawn_old witch_bride", false))
				{
					if(CounterData[iWitchesSpawned] == PluginSettings[hWitchLimit].IntValue)
						PrintToChat(param1,  "%T", "Witch Limit", param1);
					else
						CounterData[iWitchesSpawned]++;
				}
				else if(StrContains(g_esPlayerData[param1].sItemName, "z_spawn_old", false) != -1 && StrContains(g_esPlayerData[param1].sItemName, "mob", false) == -1)
				{
					if(IsPlayerAlive(param1) || IsGhost(param1))
						return;

					bool[] bResetGhost = new bool[MaxClients + 1];
					bool[] bResetLifeState = new bool[MaxClients + 1];
					for(int i = 1; i <= MaxClients; i++)
					{
						if(i == param1 || !IsClientInGame(i) || GetClientTeam(i) != 3 || IsFakeClient(i))
							continue;

						if(IsGhost(i))
						{
							bResetGhost[i] = true;
							SetEntProp(i, Prop_Send, "m_isGhost", 0);
						}
						else if(!IsPlayerAlive(i))
						{
							bResetLifeState[i] = true;
							SetEntProp(i, Prop_Send, "m_lifeState", 0);
						}
					}

					CheatCommand(param1, g_esPlayerData[param1].sItemName);

					int iMaxRetry = PluginSettings[hSpawnAttempts].IntValue;
					for(int i; i < iMaxRetry; i++)
					{
						if(!IsPlayerAlive(param1))
							CheatCommand(param1, g_esPlayerData[param1].sItemName);
					}

					if(IsPlayerAlive(param1))
					{
						strcopy(g_esPlayerData[param1].sBought, 64, g_esPlayerData[param1].sItemName);
						g_esPlayerData[param1].iBoughtCost = g_esPlayerData[param1].iItemCost;
						RemovePoints(param1, g_esPlayerData[param1].iItemCost);
					}
					else
						PrintToChat(param1, "%s %T", MSGTAG, "Spawn Failed", param1);

					for(int i = 1; i <= MaxClients; i++)
					{
						if(bResetGhost[i]) 
							SetEntProp(i, Prop_Send, "m_isGhost", 1);
						if(bResetLifeState[i]) 
							SetEntProp(i, Prop_Send, "m_lifeState", 1);
					}
					return;
				}
				strcopy(g_esPlayerData[param1].sBought, 64, g_esPlayerData[param1].sItemName);
				g_esPlayerData[param1].iBoughtCost = g_esPlayerData[param1].iItemCost;
				RemovePoints(param1, g_esPlayerData[param1].iItemCost);
				CheatCommand(param1, g_esPlayerData[param1].sItemName);
			}
		}
		case MenuAction_Cancel:
		{
			strcopy(g_esPlayerData[param1].sItemName, 64, g_esPlayerData[param1].sBought);
			g_esPlayerData[param1].iItemCost = g_esPlayerData[param1].iBoughtCost;
		}
		case MenuAction_End:
			delete menu;
	}
}
