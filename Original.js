const { Client, LocalAuth } = require('whatsapp-web.js');
const axios = require('axios');
const qrcode = require('qrcode-terminal');
const readXlsxFile = require('read-excel-file/node');
const path = require('path');
const puppeteer = require('puppeteer-core');

const client = new Client({
    authStrategy: new LocalAuth()
});

client.on('qr', (qr) => {
    console.log('Scan the QR code below to login:');
    qrcode.generate(qr, { small: true });
});

const userSessions = new Map();

let cachedSessionCookies = null;
let sessionCookiesExpiry = null;

const getSessionCookies = async () => {
    const currentTime = Date.now();
    if (cachedSessionCookies && sessionCookiesExpiry && currentTime < sessionCookiesExpiry) {
        return cachedSessionCookies;
    } else {
        cachedSessionCookies = await authenticateAndRetrieveCookies();
        sessionCookiesExpiry = Date.now() + (50 * 60 * 1000);
        return cachedSessionCookies;
    }
};

const authenticateAndRetrieveCookies = async () => {
    let browser;
    try {
        browser = await puppeteer.launch({
            headless: "new",
            executablePath: 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
            args: ['--no-sandbox', '--disable-setuid-sandbox']
        });
        const page = await browser.newPage();
        await page.goto('https://jh.railwire.co.in/rlogin');
        await page.waitForSelector('#login-box');
        const captchaCode = await page.$eval('#captcha_code', el => el.textContent.trim());
        await page.type('#username', 'support');
        await page.type('#password', 'touch5sp');
        await page.type('#code', captchaCode);
        await page.click('#btn_rlogin');
        await page.waitForNavigation({ waitUntil: 'networkidle0', timeout: 120000 });
        const currentUrl = page.url();
        if (currentUrl.includes('billcntl')) {
            console.log('Login successful!');
        } else {
            throw new Error('Login failed. Try again.');
        }
        const cookies = await page.cookies();
        const railwireCookie = cookies.find(cookie => cookie.name === 'railwire_cookie_name');
        const ciSessionCookie = cookies.find(cookie => cookie.name === 'ci_session');
        if (!railwireCookie || !ciSessionCookie) {
            throw new Error('Please retry facing trouble!');
        }
        return { railwireCookie, ciSessionCookie };
    } catch (error) {
        console.error('Error during authentication', error.message);
        return null;
    } finally {
        if (browser) {
            await browser.close();
        }
    }
};

const resetUserSession = async (userData) => {
    const cookies = await getSessionCookies();
    if (!cookies) {
        console.error('Please close and try again cookies issue');
        return false;
    }
    const url = 'https://jh.railwire.co.in/billcntl/endacctsession';
    const payload = new URLSearchParams({
        uname: userData.Username,
        railwire_test_name: cookies.railwireCookie.value
    });
    const cookieHeader = `${cookies.railwireCookie.name}=${cookies.railwireCookie.value}; ${cookies.ciSessionCookie.name}=${cookies.ciSessionCookie.value}`;
    try {
        const response = await axios.post(url, payload.toString(), {
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                'Cookie': cookieHeader
            }
        });
        console.log(`Status: ${response.data.STATUS}`);
        console.log(response.data.message || 'No message provided');
        return response.data.STATUS === 'OK';
    } catch (error) {
        console.error('Error during session reset:', error.message);
        return false;
    }
};

const resetPortalAndPppoe = async (userData) => {
    const cookies = await getSessionCookies();
    if (!cookies) {
        console.error('Please close and try again cookies issue');
        return { portalReset: false, pppoeReset: false };
    }
    const cookieHeader = `${cookies.railwireCookie.name}=${cookies.railwireCookie.value}; ${cookies.ciSessionCookie.name}=${cookies.ciSessionCookie.value}`;
    const url = 'https://jh.railwire.co.in/subapis/subpassreset';
    const commonData = {
        subid: userData.SubscriberId,
        mobileno: userData.MobileNo,
        railwire_test_name: cookies.railwireCookie.value
    };
    const portalResetData = new URLSearchParams({ ...commonData, flag: 'Bill' });
    const pppoeResetData = new URLSearchParams({ ...commonData, flag: 'Internet' });
    try {
        const [portalResetResponse, pppoeResetResponse] = await Promise.all([
            axios.post(url, portalResetData.toString(), {
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                    'Cookie': cookieHeader
                }
            }),
            axios.post(url, pppoeResetData.toString(), {
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                    'Cookie': cookieHeader
                }
            })
        ]);
        console.log(`Portal Reset Status: ${portalResetResponse.data.STATUS}`);
        console.log(portalResetResponse.data.message || 'Billing Password Reset Completed!');
        console.log(`PPPoE Reset Status: ${pppoeResetResponse.data.STATUS}`);
        console.log(pppoeResetResponse.data.message || 'Internet Password Reset Completed!');
        return {
            portalReset: portalResetResponse.data.STATUS === 'OK',
            pppoeReset: pppoeResetResponse.data.STATUS === 'OK'
        };
    } catch (error) {
        console.error('Error during portal and PPPoE reset:', error.message);
        return { portalReset: false, pppoeReset: false };
    }
};

const loadUserDataFromExcel = async () => {
    const filePath = path.resolve(__dirname, 'User.xlsx');
    const rows = await readXlsxFile(filePath);
    const [header, ...data] = rows;
    const headerMap = header.reduce((acc, col, index) => {
        acc[col] = index;
        return acc;
    }, {});
    return data.map(row => ({
        MobileNo: row[headerMap['MobileNo']].toString().trim(),
        Username: row[headerMap['Username']].toString().trim().toLowerCase(),
        SubscriberId: row[headerMap['SubscriberId']].toString().trim(),
        Name: row[headerMap['Name']].toString().trim()
    }));
};

const NewIdea = async (userCode) => {
    let browser;
    try {
        browser = await puppeteer.launch({
            headless: "new",
            executablePath: 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
            args: ['--no-sandbox', '--disable-setuid-sandbox']
        });
        const page = await browser.newPage();
        await page.goto('https://jh.railwire.co.in/rlogin');
        await page.waitForSelector('#login-box');

        const captchaCode = await page.$eval('#captcha_code', el => el.textContent.trim());
        await page.type('#username', 'support');
        await page.type('#password', 'touch5sp');
        await page.type('#code', captchaCode);
        await page.click('#btn_rlogin');
        await page.waitForNavigation({ waitUntil: 'networkidle0', timeout: 120000 });

        const currentUrl = page.url();
        if (currentUrl.includes('billcntl')) {
            console.log('Login successful!');
        } else {
            throw new Error('Login failed. Try again.');
        }

        await page.type('#user-search', userCode);
        await page.keyboard.press('Enter');
        await page.waitForSelector('table tbody tr');

        const userData = await page.evaluate(() => {
            const row = document.querySelector('table tbody tr');
            if (!row) return null;

            const id = row.querySelector('td:nth-child(1)').innerText.trim(); // Subscriber ID
            const username = row.querySelector('td:nth-child(2) a').innerText.trim(); // JH Code
            const mobileNo = row.querySelector('td:nth-child(6)').innerText.trim(); // Mobile Number

            return { id, username, mobileNo };
        });

        if (userData) {
            console.log('User data fetched from portal:', userData);
            return {
                Username: userData.username,
                MobileNo: userData.mobileNo,
                SubscriberId: userData.id
            };
        } else {
            console.error('No user data found on the portal.');
            return null;
        }
    } catch (error) {
        console.error('Error fetching user data from portal:', error.message);
        return null;
    } finally {
        if (browser) {
            await browser.close();
        }
    }
};

const handleIncomingMessage = async (message) => {
    const from = message.from;
    const messageBody = message.body.toLowerCase().trim();
    const author = message.author || from;
    console.log(`User Detail: ${author}`);
    console.log(`Message: ${messageBody}`);

    const codePattern = /jh\.\w+\.\w+/i;  // Regular expression to match JH code
    const codeMatch = messageBody.match(codePattern);
    let actionType = null;

    // Determine the action type based on keywords
    if (messageBody.includes('session')) {
        actionType = 'session';
    } else if (messageBody.includes('reset') || messageBody.includes('password')) {
        actionType = 'reset';
    }

    if (codeMatch) {
        // If a JH code is present, store it in the user session without fetching the user data yet
        const userCode = codeMatch[0].toLowerCase();
        console.log(`Extracted user code: ${userCode}`);

        userSessions.set(author, { userCode, userData: null });  // Store the code, but no userData yet
        console.log('Stored JH code. Waiting for action keyword...');
    }

    if (actionType && userSessions.has(author)) {
        // If an action keyword is received and the JH code was previously stored
        const { userCode, userData } = userSessions.get(author);

        if (!userData) {
            console.log(`Fetching user data for code ${userCode}...`);

            try {
                // Load user data from Excel
                const userDataList = await loadUserDataFromExcel();
                let fetchedUserData = userDataList.find(row => row.Username.toLowerCase() === userCode);

                if (!fetchedUserData) {
                    console.log('User data not found in Excel, attempting to fetch from portal...');
                    // Fetch user data from the portal
                    fetchedUserData = await NewIdea(userCode);
                }

                if (fetchedUserData) {
                    console.log(`User data found for code ${userCode}:`);
                    console.log(` Username: ${fetchedUserData.Username}`);
                    console.log(` MobileNo: ${fetchedUserData.MobileNo}`);
                    console.log(` SubscriberId: ${fetchedUserData.SubscriberId}`);

                    // Update the user session with the fetched user data
                    userSessions.set(author, { userCode, userData: fetchedUserData });

                    // Now process the action type after fetching user data
                    await processAction(actionType, from, userCode, fetchedUserData);
                } else {
                    console.log(`No user data found for code ${userCode}`);
                    await client.sendMessage(from, `Incorrect data found for code: ${userCode}`);
                }
            } catch (error) {
                console.error('Error processing message:', error.message);
                await client.sendMessage(from, `Error: ${error.message}`);
            }
        } else {
            // If userData is already fetched, directly process the action
            await processAction(actionType, from, userCode, userData);
        }
    } else {
        console.log('No action type identified or user session not found.');
    }
};


// Separate function to handle the action once both JH code and keyword are received
const processAction = async (actionType, from, userCode, userData) => {
    if (actionType === 'session') {
        console.log('Processing session reset...');
        const resetSuccessful = await resetUserSession(userData);
        if (resetSuccessful) {
            await client.sendMessage(from, `Session reset successful for ${userCode}.`);
        } else {
            await client.sendMessage(from, `Session reset failed for ${userCode}. Please try again.`);
        }
    } else if (actionType === 'reset') {
        console.log('Processing password reset...');
        const resetResults = await resetPortalAndPppoe(userData);
        if (resetResults.portalReset && resetResults.pppoeReset) {
            await client.sendMessage(from, `Portal and Internet reset successful for ${userCode}.`);
        } else {
            const failedResetTypes = [];
            if (!resetResults.portalReset) {
                failedResetTypes.push('Portal');
            }
            if (!resetResults.pppoeReset) {
                failedResetTypes.push('Internet');
            }
            await client.sendMessage(from, `Password reset failed for ${userCode}. Failed to reset: ${failedResetTypes.join(', ')}. Please try again.`);
        }
    }
    userSessions.delete(from);  // Clean up user session after action is completed
};


// Event listeners for WhatsApp client
client.on('ready', () => {
    console.log('WhatsApp Web client is ready!');
});


client.on('message', handleIncomingMessage);

client.initialize();
