const { fetch } = require('undici');
const { v4: uuidv4 } = require('uuid');
const pLimit = require('p-limit');

const CommonHeaders = {
    'Content-Type': 'application/json',
    'Accept-Language': 'en-IN,en-GB;q=0.9,en;q=0.8',
    'Accept-Encoding': 'gzip, deflate, br',
};

const UniqVoteSet = new Set();

function GenerateUniqueVote() {
    let UniqVote;
    do {
        UniqVote = `uniq_1${Math.floor(Math.random() * 1e9)}`;
    } while (UniqVoteSet.has(UniqVote));

    UniqVoteSet.add(UniqVote);

    if (UniqVoteSet.size > 10000) {
        UniqVoteSet.clear();
    }

    return UniqVote;
}

const IphoneModels = [
    "iPhone8,1", "iPhone8,2", "iPhone8,3", "iPhone8,4",
    "iPhone9,1", "iPhone9,2", "iPhone9,3", "iPhone9,4",
    "iPhone10,1", "iPhone10,2", "iPhone10,3", "iPhone10,4",
    "iPhone11,2", "iPhone11,4", "iPhone11,6", "iPhone11,8",
    "iPhone12,1", "iPhone12,3", "iPhone12,5", "iPhone12,8",
    "iPhone13,1", "iPhone13,2", "iPhone13,3", "iPhone13,4",
    "iPhone14,2", "iPhone14,3", "iPhone14,4", "iPhone14,5",
    "iPhone15,2", "iPhone15,3", "iPhone15,4", "iPhone15,5"
];

const IosVersions = [
    "14.1", "14.2", "14.3", "14.4", "15.0", "15.1", "15.2", "15.3", "15.4",
    "16.0", "16.1", "16.2", "16.3", "16.4", "17.6", "18.1"
];

function GetRandomUserAgent() {
    const RandomIphoneModel = IphoneModels[Math.floor(Math.random() * IphoneModels.length)];
    const RandomIosVersion = IosVersions[Math.floor(Math.random() * IosVersions.length)];

    const UserAgent1 = `JioCinema/241203000 (mobile; iOS/${RandomIosVersion}; smartphone; Apple ${RandomIphoneModel}) Alamofire/5.9.1`;
    const UserAgent2 = `Mozilla/5.0 (iPhone; CPU iPhone OS ${RandomIosVersion.replace('.', '_')} like Mac OS X) AppleWebKit/605.1.18 (KHTML, like Gecko) Mobile/15E148`;

    return { UserAgent1, UserAgent2 };
}

function FetchWithTimeout(url, options, timeout = 5000) {
    const timeoutPromise = new Promise((_, reject) => {
        setTimeout(() => reject(new Error('Request timed out')), timeout);
    });
    return Promise.race([fetch(url, options), timeoutPromise]);
}

async function ProcessVote(voteNumber) {
    const UniqueID = uuidv4();
    const { UserAgent1, UserAgent2 } = GetRandomUserAgent();
    const SpecificModels = [
        "iPhone 8", "iPhone 8 Plus", 
        "iPhone X", "iPhone XR", "iPhone XS", "iPhone XS Max",
        "iPhone 11", "iPhone 11 Pro", "iPhone 11 Pro Max",
        "iPhone 12", "iPhone 12 Mini", "iPhone 12 Pro", "iPhone 12 Pro Max",
        "iPhone 13", "iPhone 13 Mini", "iPhone 13 Pro", "iPhone 13 Pro Max",
        "iPhone 14", "iPhone 14 Plus", "iPhone 14 Pro", "iPhone 14 Pro Max",
        "iPhone 15", "iPhone 15 Plus", "iPhone 15 Pro", "iPhone 15 Pro Max",
        "iPhone 16", "iPhone 16 Plus", "iPhone 16 Pro", "iPhone 16 Pro Max"
    ];

    const SpecificModel = SpecificModels[Math.floor(Math.random() * SpecificModels.length)];

    try {
        // Step 1: Guest Authentication
        const AuthPayload = {
            "adId": UniqueID,
            "freshLaunch": true,
            "deviceType": "phone",
            "appName": "RJIL_JioCinema",
            "deviceId": UniqueID,
            "os": "ios",
            "appVersion": "24.12.030"
        };

        const AuthRequestHeaders = {
            ...CommonHeaders,
            "manufacturer": "Apple",
            "model": SpecificModel,
            "device-id": UniqueID,
            "User-Agent": UserAgent1
        };

        const AuthResponse = await FetchWithTimeout(
            "https://auth-jiocinema.voot.com/tokenservice/apis/v4/guest",
            {
                method: "POST",
                headers: AuthRequestHeaders,
                body: JSON.stringify(AuthPayload),
            },
            10000
        );

        if (!AuthResponse.ok) throw new Error(`Authentication failed: ${AuthResponse.statusText}`);
        const AuthData = await AuthResponse.json();
        const AuthToken = AuthData.authToken;

        // Step 2: Get Interactivity Token
        const InteractivityPayload = { "appVersion": "24.12.030" };
        const InteractivityRequestHeaders = {
            ...CommonHeaders,
            "appname": "RJIL_JioEngage",
            "usertype": "svod",
            "device-id": UniqueID,
            "profileid": AuthData.profileId,
            "accesstoken": AuthToken,
            "User-Agent": UserAgent1
        };

        const InteractivityResponse = await FetchWithTimeout(
            "https://auth-jiocinema.voot.com/tokenservice/apis/v4/interactivitytoken",
            {
                method: "POST",
                headers: InteractivityRequestHeaders,
                body: JSON.stringify(InteractivityPayload),
            },
            10000
        );

        const InteractivityData = await InteractivityResponse.json();
        const InteractivityToken = InteractivityData.accessToken;

        // Step 3: Login
        const LoginPayload = {
            "type": "alpha",
            "isLoggedIn": "true",
            "deeplinkurl": "https://go.jc.fm/fRhd/ffiat790",
            "noPlayerMode": "true",
            "platform": "ios",
            "mode": "portrait"
        };

        const LoginRequestHeaders = {
            ...CommonHeaders,
            "Authorization": InteractivityToken,
            "User-Agent": UserAgent2
        };

        const LoginResponse = await FetchWithTimeout(
            "https://engagevotingapi.jiocinema.com/login",
            {
                method: "POST",
                headers: LoginRequestHeaders,
                body: JSON.stringify(LoginPayload),
            },
            10000
        );

        const LoginData = await LoginResponse.json();
        const LoginToken = LoginData.token;

        // Step 4: Submit Vote
        const UniqVote = GenerateUniqueVote();
        const VotePayload = {
            "answer": ["alpha_Chaahat Pandey"],
            "uniqVote": UniqVote,
            "utype": "svod",
            "mode": "portrait"
        };

        const VoteRequestHeaders = {
            ...CommonHeaders,
            "Authorization": LoginToken,
            "Referer": "https://engage-web.jiocinema.com",
            "User-Agent": UserAgent2
        };

        const VoteResponse = await FetchWithTimeout(
            "https://engagevotingapi.jiocinema.com/api/voting/questions/q-f7e4d6a5-08b2-4f0e-b886-7f22b7208a78/answer",
            {
                method: "POST",
                headers: VoteRequestHeaders,
                body: JSON.stringify(VotePayload),
            },
            10000
        );

        const VoteData = await VoteResponse.json();
        console.log(`Vote ${voteNumber} >> ID: ${AuthData.profileId} >> Data: ${JSON.stringify(VoteData)}`);

    } catch (error) {
        console.error(`Error processing vote ${voteNumber}: ${error.message}`);
    }
}

// Run multiple votes
async function MultipleVotes(count) {
    const Limit = pLimit(12);
    const Promises = [];

    for (let i = 0; i < count; i++) {
        Promises.push(Limit(() => ProcessVote(i + 1)));
    }

    await Promise.all(Promises);
}

MultipleVotes(15000);