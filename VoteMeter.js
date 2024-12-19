const fetch = require('node-fetch');
const { v4: uuidv4 } = require('uuid');
const pLimit = require('p-limit');

const commonHeaders = {
    'Content-Type': 'application/json',
    'Accept-Language': 'en-IN,en-GB;q=0.9,en;q=0.8',
    'Accept-Encoding': 'gzip, deflate, br',
};

const uniqVoteSet = new Set();

function delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

function generateUniqueVote() {
    let uniqVote;
    do {
        uniqVote = `uniq_1${Math.floor(Math.random() * 1e9)}`;
    } while (uniqVoteSet.has(uniqVote));

    uniqVoteSet.add(uniqVote);

    if (uniqVoteSet.size > 10000) { 
        uniqVoteSet.clear();
    }

    return uniqVote;
}

const iphoneModels = [
    "iPhone8,1", "iPhone8,2", "iPhone8,3", "iPhone8,4", 
    "iPhone9,1", "iPhone9,2", "iPhone9,3", "iPhone9,4", 
    "iPhone10,1", "iPhone10,2", "iPhone10,3", "iPhone10,4", 
    "iPhone11,2", "iPhone11,4", "iPhone11,6", "iPhone11,8", 
    "iPhone12,1", "iPhone12,3", "iPhone12,5", "iPhone12,8", 
    "iPhone13,1", "iPhone13,2", "iPhone13,3", "iPhone13,4", 
    "iPhone14,2", "iPhone14,3", "iPhone14,4", "iPhone14,5", 
    "iPhone15,2", "iPhone15,3", "iPhone15,4", "iPhone15,5"
];

const iosVersions = [
    "14.1", "14.2", "14.3", "14.4", "15.0", "15.1", "15.2", "15.3", "15.4",
    "16.0", "16.1", "16.2", "16.3", "16.4", "17.6", "18.1"
];

function getRandomUserAgent() {
    const randomIphoneModel = iphoneModels[Math.floor(Math.random() * iphoneModels.length)];
    const randomIosVersion = iosVersions[Math.floor(Math.random() * iosVersions.length)];

    // First User-Agent format: JioCinema/241120000
    const userAgent1 = `JioCinema/241203000 (mobile; iOS/${randomIosVersion}; smartphone; Apple ${randomIphoneModel}) Alamofire/5.9.1`;

    // Second User-Agent format: Mozilla/5.0
    const userAgent2 = `Mozilla/5.0 (iPhone; CPU iPhone OS ${randomIosVersion.replace('.', '_')} like Mac OS X) AppleWebKit/605.1.18 (KHTML, like Gecko) Mobile/15E148`;

    return { userAgent1, userAgent2 };
}

// Main Vote Processing Logic
async function processVote(voteNumber) {
    const UniqueID = uuidv4();
    const randomModel = iphoneModels[Math.floor(Math.random() * iphoneModels.length)];  
    const { userAgent1, userAgent2 } = getRandomUserAgent(); 

    try {
        // Step 1: Guest Authentication
        const authPayload = {
            "adId": UniqueID,
            "freshLaunch": true,
            "deviceType": "phone",
            "appName": "RJIL_JioCinema",
            "deviceId": UniqueID,
            "os": "ios",
            "appVersion": "24.12.030"
        };

        const authRequestHeaders = {
            ...commonHeaders,
            "manufacturer": "Apple",
            "model": randomModel,
            "device-id": UniqueID,
            "User-Agent": userAgent1
        };

        const authResponse = await fetch(
            "https://auth-jiocinema.voot.com/tokenservice/apis/v4/guest",
            {
                method: "POST",
                headers: authRequestHeaders,
                body: JSON.stringify(authPayload),
                timeout: 50000
            }
        );

        if (!authResponse.ok) throw new Error(`Authentication failed: ${authResponse.statusText}`);
        const authData = await authResponse.json();
        const authToken = authData.authToken;

        // Step 2: Get Interactivity Token
        const interactivityPayload = { "appVersion": "24.12.030" };
        const interactivityRequestHeaders = {
            ...commonHeaders,
            "appname": "RJIL_JioEngage",
            "usertype": "svod",
            "device-id": UniqueID,
            "profileid": authData.profileId,
            "accesstoken": authToken,
            "User-Agent": userAgent1
        };

        const interactivityResponse = await fetch(
            "https://auth-jiocinema.voot.com/tokenservice/apis/v4/interactivitytoken",
            {
                method: "POST",
                headers: interactivityRequestHeaders,
                body: JSON.stringify(interactivityPayload),
                timeout: 50000
            }
        );

        if (!interactivityResponse.ok) throw new Error(`Interactivity Token request failed: ${interactivityResponse.statusText}`);
        const interactivityData = await interactivityResponse.json();
        const interactivityToken = interactivityData.accessToken;

        // Step 3: Login
        const loginPayload = {
            "type": "alpha",
            "isLoggedIn": "true",
            "deeplinkurl": "https://go.jc.fm/fRhd/ffiat790",
            "noPlayerMode": "true",
            "platform": "ios",
            "mode": "portrait"
        };

        const loginRequestHeaders = {
            ...commonHeaders,
            "Authorization": interactivityToken,
            "User-Agent": userAgent2
        };

        const loginResponse = await fetch(
            "https://engagevotingapi.jiocinema.com/login",
            {
                method: "POST",
                headers: loginRequestHeaders,
                body: JSON.stringify(loginPayload),
                timeout: 50000
            }
        );

        if (!loginResponse.ok) throw new Error(`Login failed: ${loginResponse.statusText}`);
        const loginData = await loginResponse.json();
        const loginToken = loginData.token;

        // Step 4: Submit Vote
        const uniqVote = generateUniqueVote();
        const votePayload = {
            "answer": ["alpha_Digvijay Rathee"],
            "uniqVote": uniqVote,
            "utype": "svod",
            "mode": "portrait"
        };

        const voteRequestHeaders = {
            ...commonHeaders,
            "Authorization": loginToken,
            "Referer": "https://engage-web.jiocinema.com",
            "User-Agent": userAgent2
        };

        const voteResponse = await fetch(
            "https://engagevotingapi.jiocinema.com/api/voting/questions/q-ba6a322f-9754-4627-8c0e-0bb670c35f59/answer",
            {
                method: "POST",
                headers: voteRequestHeaders,
                body: JSON.stringify(votePayload),
                timeout: 50000
            }
        );

        if (!voteResponse.ok) throw new Error(`Vote submission failed: ${voteResponse.statusText}`);
        const voteData = await voteResponse.json();

        console.log(`Vote ${voteNumber} >> ID: ${authData.profileId} >> Data: ${JSON.stringify(voteData)}`);

    } catch (error) {
        if (error.message.includes("ETIMEDOUT")) {
            // Ignore timeout errors and skip the vote
            console.log(`Vote ${voteNumber} >> Timeout. Ignoring this vote.`);
        } else {
            // Log other errors
            console.error(`Error processing vote ${voteNumber}: ${error.message}`);
        }
    }
}

async function multipleVotes(count) {
    const batchSize = 200;
    const delayTime = 1000;

    const limit = pLimit(150);
    let voteCount = 0;

    while (voteCount < count) {
        const promises = Array.from(
            { length: Math.min(batchSize, count - voteCount) },
            (_, i) => limit(() => processVote(voteCount + i + 1))
        );

        await Promise.all(promises);
        voteCount += batchSize;

        if (voteCount < count) {
            console.log(`Batch completed. Waiting for ${delayTime / 1000} seconds...`);
            await delay(delayTime);
        }
    }
}

// Start voting
multipleVotes(100000);
