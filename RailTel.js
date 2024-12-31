const { Client, LocalAuth } = require('whatsapp-web.js');
const axios = require('axios');
const qrcode = require('qrcode-terminal');
const readXlsxFile = require('read-excel-file/node');
const path = require('path');
const puppeteer = require('puppeteer-core');
const cheerio = require('cheerio');
const XLSX = require('xlsx');

const client = new Client({ authStrategy: new LocalAuth() });
const userSessions = new Map();
let cachedSessionCookies = null;
let userDataCache = null;

const baseURL = 'https://jh.railwire.co.in';
const mainURL = `${baseURL}/billcntl/kycpending`;
let jhCodeMap = null;

const generateQRCode = (qr) => {
    console.log('Scan the QR code below to login:');
    qrcode.generate(qr, { small: true });
};

const getCookies = async () => {
    if (cachedSessionCookies) return cachedSessionCookies;
    cachedSessionCookies = await authenticate('support', 'Touch5SP');
    return cachedSessionCookies;
};

const loadUserDataFromExcel = async () => {
    if (userDataCache) return userDataCache;
    const filePath = path.resolve(__dirname, 'User.xlsx');
    const rows = await readXlsxFile(filePath);
    const [header, ...data] = rows;
    const headerMap = header.reduce((acc, col, index) => { acc[col] = index; return acc; }, {});
    userDataCache = new Map(data.flatMap(row => [
        [row[headerMap['Username']].toString().trim().toLowerCase(), {
            MobileNo: row[headerMap['MobileNo']].toString().trim(),
            Username: row[headerMap['Username']].toString().trim().toLowerCase(),
            SubscriberId: row[headerMap['SubscriberId']].toString().trim(),
        }],
        [row[headerMap['SubscriberId']].toString().trim(), {
            MobileNo: row[headerMap['MobileNo']].toString().trim(),
            Username: row[headerMap['Username']].toString().trim().toLowerCase(),
            SubscriberId: row[headerMap['SubscriberId']].toString().trim(),
        }]
    ]));
    return userDataCache;
};

const loadExcelData = () => {
    if (jhCodeMap) return;
    try {
        const workbook = XLSX.readFile(path.join(__dirname, 'Page.xlsx'));
        const sheet = workbook.Sheets[workbook.SheetNames[0]];
        const data = XLSX.utils.sheet_to_json(sheet);
        jhCodeMap = new Map();
        partnerIndex = new Map();
        
        data.forEach(row => {
            const partner = row['Associated Partner']?.toLowerCase();
            const jhCode = row['JH Code'];
            
            if (partner && jhCode) {
                jhCodeMap.set(partner, jhCode);
                const words = partner.split(' ');
                words.forEach(word => {
                    if (word.length > 2) {
                        if (!partnerIndex.has(word)) {
                            partnerIndex.set(word, new Set());
                        }
                        partnerIndex.get(word).add(partner);
                    }
                });
            }
        });
    } catch (err) {
        console.error(`Error reading Excel file: ${err.message}`);
    }
};

const launchBrowser = async () => {
    return puppeteer.launch({
        headless: "new",
        executablePath: 'C:\\Program Files\\Google\\Chrome Beta\\Application\\chrome.exe',
        args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage',
            '--disable-gpu', '--no-zygote', '--disable-extensions', 
            '--disable-software-rasterizer', '--disable-features=Translate,BackForwardCache,InterestCohort',
            '--mute-audio', '--disable-background-timer-throttling', 
            '--disable-backgrounding-occluded-windows', '--disable-renderer-backgrounding',
            '--no-first-run', '--disable-infobars'],
        ignoreDefaultArgs: ['--enable-automation'],
        defaultViewport: { width: 500, height: 500 }
    });
};

async function retryOperation(operation, maxRetries = 3, delay = 1000) {
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            return await operation();
        } catch (error) {
            if (attempt === maxRetries) throw error;
            await new Promise(resolve => setTimeout(resolve, delay * attempt));
        }
    }
}

const authenticate = async (username, password) => {
    return retryOperation(async () => {
        let browser;
        try {
            browser = await launchBrowser();
            const page = await browser.newPage();
            await page.goto('https://jh.railwire.co.in/rlogin', { waitUntil: 'domcontentloaded' }); 
            await page.waitForSelector('#login-box'); 
            const captchaCode = await page.$eval('#captcha_code', el => el.textContent.trim());
            await page.type('#username', username); 
            await page.type('#password', password);
            await page.type('#code', captchaCode);
            await page.click('#btn_rlogin');
            await page.waitForNavigation({ waitUntil: 'domcontentloaded', timeout: 60000 });
            const currentUrl = page.url();
            if (!currentUrl.includes('billcntl') && !currentUrl.includes('subcntl')) {
                throw new Error('Login failed. Try again.');
            }
            console.log('Login successful!');
            const cookies = await page.cookies();
            const railwireCookie = cookies.find(cookie => cookie.name === 'railwire_cookie_name');
            const ciSessionCookie = cookies.find(cookie => cookie.name === 'ci_session');
            if (!railwireCookie || !ciSessionCookie) throw new Error('Required cookies not found.');
            return { railwireCookie, ciSessionCookie };
        } finally {
            if (browser) await browser.close();
        }
    });
};

const fetchUserDataFromPortal = async (userCode) => {
    let browser;
    const maxRetries = 3; 
    const delayBetweenRetries = 150;
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            browser = await launchBrowser();
            const page = await browser.newPage();
            await page.goto('https://jh.railwire.co.in/rlogin', { waitUntil: 'domcontentloaded' }); 
            await page.waitForSelector('#login-box', { timeout: 10000 });
            const captchaCode = await page.$eval('#captcha_code', el => el.textContent.trim());
            await page.type('#username', 'support');
            await page.type('#password', 'Touch5SP');
            await page.type('#code', captchaCode);
            await page.click('#btn_rlogin');
            await page.waitForNavigation({ waitUntil: 'domcontentloaded', timeout: 90000 });
            const currentUrl = page.url();
            if (!currentUrl.includes('billcntl')) throw new Error('Login failed. Try again.');
            await page.waitForSelector('#user-search', { timeout: 10000 });
            await page.type('#user-search', userCode);
            await page.keyboard.press('Enter');
            await page.waitForSelector('table tbody tr', { timeout: 10000 });
            const userData = await page.evaluate(() => {
                const row = document.querySelector('table tbody tr');
                if (!row) return null;
                return {
                    id: row.querySelector('td:nth-child(1)').innerText.trim(),
                    username: row.querySelector('td:nth-child(2) a').innerText.trim(),
                    mobileNo: row.querySelector('td:nth-child(6)').innerText.trim()
                };
            });
            return userData ? {
                Username: userData.username,
                MobileNo: userData.mobileNo,
                SubscriberId: userData.id
            } : null;
       } catch (error) {
            console.error(`Attempt ${attempt} failed:`, error.message);
            if (attempt === maxRetries) {
                console.log(`Max retries completed. Authentication Failed!`);
                return null;
            }
            await new Promise(resolve => setTimeout(resolve, delayBetweenRetries));

        } finally {
            if (browser) await browser.close();
        }
    }
};

const resetSession = async (userData, cookies) => {
    const url = 'https://jh.railwire.co.in/billcntl/endacctsession';
    const payload = new URLSearchParams({
        uname: userData.Username,
        railwire_test_name: cookies.railwireCookie.value
    }).toString();
    try {
        const response = await axios.post(url, payload, {
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                'Cookie': `${cookies.railwireCookie.name}=${cookies.railwireCookie.value}; ${cookies.ciSessionCookie.name}=${cookies.ciSessionCookie.value}`
            }
        });
        if (response.data.STATUS === undefined) {
            console.log('Cookies invalid, retrying...');
            cachedSessionCookies = await authenticate('support', 'Touch5SP');
            return await resetSession(userData, cachedSessionCookies);
        }
        console.log(`Session reset response status: ${response.data.STATUS}`);
        return response.data.STATUS === 'OK';
    } catch (error) {
        console.error('Session reset error:', error.message);
        return false;
    }
};

const resetPassword = async (userData, cookies) => {
    const url = 'https://jh.railwire.co.in/subapis/subpassreset';
    const requests = ['Bill', 'Internet'].map(flag => {
        const payload = new URLSearchParams();
        payload.append('subid', userData.SubscriberId);
        payload.append('mobileno', userData.MobileNo);
        payload.append('flag', flag);
        payload.append('railwire_test_name', cookies.railwireCookie.value);
        
        const payloadString = payload.toString();
                return axios.post(url, payloadString, {
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                'Cookie': `${cookies.railwireCookie.name}=${cookies.railwireCookie.value}; ${cookies.ciSessionCookie.name}=${cookies.ciSessionCookie.value}`
            }
        });
    });

    try {
        const [portalResponse, pppoeResponse] = await Promise.all(requests);
        const portalStatus = portalResponse.data.STATUS;
        const pppoeStatus = pppoeResponse.data.STATUS;
        if (portalStatus === undefined || pppoeStatus === undefined) {
            console.log('Cookies invalid, retrying...');
            cachedSessionCookies = await authenticate('support', 'Touch5SP');
            return await resetPassword(userData, cachedSessionCookies);
        }
        console.log('Password reset responses:', { portal: portalStatus, pppoe: pppoeStatus });
        return { portalReset: portalStatus === 'OK', pppoeReset: pppoeStatus === 'OK' };
    } catch (error) {
        console.error('Password reset error:', error.message);
        return { portalReset: false, pppoeReset: false };
    }
};


const getUserIdentifier = (message) => {
    return message.fromMe ? message.to : (message.author || message.from);
};

const waitForReply = async (originalMessage) => {
    const userIdentifier = getUserIdentifier(originalMessage);
    return new Promise((resolve) => {
        const listener = (message) => {
            if (getUserIdentifier(message) === userIdentifier) {
                client.removeListener('message', listener);
                resolve(message);
            }
        };
        client.on('message', listener);
    });
};

const SendOTP = async (username, cookies) => {
    const url = 'https://jh.railwire.co.in/subcntl/getotp_reactivation/';
    const headers = {
        'Accept': '*/*',
        'Cookie': `railwire_cookie_name=${cookies.railwireCookie.value}; ci_session=${cookies.ciSessionCookie.value}`,
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
    };

    const data = new URLSearchParams({
        'fusername': username.toLowerCase(),
        'railwire_test_name': cookies.railwireCookie.value,
    });

    try {
        const response = await axios.post(url, data.toString(), { headers });
        console.log('OTP Request Response:', response.data);
        return response.data.STATUS === 'OK';
    } catch (error) {
        console.error('OTP request error:', error.message);
        return false;
    }
};

const validateOTP = async (otp, cookies) => {
    const validateUrl = 'https://jh.railwire.co.in/subcntl/validateotp/';
    const payload = new URLSearchParams({
        otp: otp,
        railwire_test_name: cookies.railwireCookie.value,
    }).toString();

    const validateHeaders = {
        'Accept': '*/*',
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'Origin': 'https://jh.railwire.co.in',
        'Referer': 'https://jh.railwire.co.in/subcntl/user_reactivate',
        'X-Requested-With': 'XMLHttpRequest',
        'Cookie': `railwire_cookie_name=${cookies.railwireCookie.value}; ci_session=${cookies.ciSessionCookie.value}`,
    };

    try {
        const validationResponse = await axios.post(validateUrl, payload, { headers: validateHeaders });
        console.log('Validation Response:', validationResponse.data);
        return validationResponse.data && validationResponse.data.STATUS === 'OK';
    } catch (error) {
        console.error('OTP validation error:', error.message);
        return false;
    }
};

const handleReactivation = async (message) => {
    const userIdentifier = getUserIdentifier(message);
    const chat = await message.getChat();

    await chat.sendMessage(`Username:`);
    const usernameMessage = await waitForReply(message);
    const username = usernameMessage.body.trim();

    if (typeof username !== 'string' || !username) {
        return;
    }

    await chat.sendMessage(`Password:`);
    const passwordMessage = await waitForReply(message);
    const password = passwordMessage.body.trim();

    const cookies = await authenticate(username, password);
    if (!cookies) {
        await chat.sendMessage(`Authentication failed. Try again.`);
        return;
    }

    userSessions.set(userIdentifier, { username, cookies });

    const otpSent = await SendOTP(username, cookies);
    if (otpSent) {
        await chat.sendMessage('OTP:');
        const otpMessage = await waitForReply(message);
        const otp = otpMessage.body.trim();

        const reactivationResult = await validateOTP(otp, cookies);
        
        console.log('OTP validation result:', reactivationResult);

        if (reactivationResult) {
            await chat.sendMessage('Account reactivated ✅');
        } else {
            await chat.sendMessage('Account reactivation failed ❌.');
        }
    } else {
        await chat.sendMessage('Failed to send OTP. Please try again later.');
    }

    userSessions.delete(userIdentifier);
};

const processActions = async (message, userIdentifier, wantsSessionReset, wantsPasswordReset) => {
    const { userCode, userData } = userSessions.get(userIdentifier);
    const userDataMap = await loadUserDataFromExcel();
    let fetchedUserData = userData || userDataMap.get(userCode);
    
    if (!fetchedUserData) {
        console.log('Not Found! Digging into SYSTEM..');
        fetchedUserData = await fetchUserDataFromPortal(userCode);
    }
    
    if (fetchedUserData) {
        userSessions.set(userIdentifier, { userCode, userData: fetchedUserData });
        const cookies = await getCookies();
        let sessionResetResult = null;
        let passwordResetResult = null;

        if (wantsSessionReset) {
            console.log('Requested Session Cleaning...');
            sessionResetResult = await resetSession(fetchedUserData, cookies);
        }
        if (wantsPasswordReset) {
            console.log('Requested Password Resetting...');
            passwordResetResult = await resetPassword(fetchedUserData, cookies);
        }

        let responseMessage = `Username: ${userCode}\n`;
        if (wantsSessionReset) {
            responseMessage += sessionResetResult ? 'Session reset done ✅\n' : 'Session not active ❌\n';
        }
        if (wantsPasswordReset) {
            if (passwordResetResult.portalReset && passwordResetResult.pppoeReset) {
                responseMessage += 'Password reset done ✅\n';
            } else {
                console.log('Reset Failed due to Server Issue.');
            }
        }
        responseMessage += '\n*RailWire Support ⚡*';
        responseMessage += '\n*_Response from Bot_ 🤖*';
        await message.reply(responseMessage);
    } else {
        console.log(`No user data found for JH code or ID: ${userCode}`);
        await message.reply(`Incorrect Username: ${userCode}`);
    }

    userSessions.delete(userIdentifier);
};

const processTasks = async (cookies, originalMessage) => {
    try {
        const { data } = await axios.get(mainURL, { 
            headers: { Cookie: `railwire_cookie_name=${cookies.railwireCookie.value}; ci_session=${cookies.ciSessionCookie.value}` },
            timeout: 5000 
        });
        const $ = cheerio.load(data);
        const submittedTasks = [];
        const verifiedTasks = [];

        $('table tbody tr').each((_, el) => {
            const cells = $(el).find('td');
            const status = $(cells[1]).text().trim().toLowerCase();
            const link = $(cells[2]).find('a').attr('href');
            const oltabid = link?.split('/')[3];
            if (status === 'submitted' && link) submittedTasks.push({ link, oltabid });
            else if (status === 'verified' && link) verifiedTasks.push({ link });
        });

        const results = {
            submitted: { total: submittedTasks.length, processed: 0 },
            verified: { total: verifiedTasks.length, processed: 0 }
        };

        for (const { link, oltabid } of submittedTasks) {
            if (await handleSubmittedForm(link, oltabid, cookies, null, originalMessage)) results.submitted.processed++;
        }
        for (const { link } of verifiedTasks) {
            if (await handleVerifiedForm(link, cookies, originalMessage)) results.verified.processed++;
        }

        return results;
    } catch (err) { 
        console.error(`Error processing tasks: ${err.message}`); 
        return null;
    }
};

const processAllForms = async (cookies, originalMessage) => {
    let totalProcessed = 0;
    let isComplete = false;

    while (!isComplete) {
        const results = await processTasks(cookies, originalMessage);
        if (results) {
            totalProcessed += results.submitted.processed + results.verified.processed;
            console.log(`Processed ${results.submitted.processed} Submitted and ${results.verified.processed} Verified Forms.`);

            if (results.submitted.processed === 0 && results.verified.processed === 0) {
                isComplete = true;
            }
        } else {
            console.log('Failed to process KYC tasks. Retrying...');
        }

        if (!isComplete) {
            console.log('Fetching Remaining Application Forms..');
            await new Promise(resolve => setTimeout(resolve, 2000)); // Wait 5 seconds before refreshing
        }
    }

    return totalProcessed;
};

const getHiddenInputs = async (link, cookies) => {
    try {
        const { data } = await axios.get(`${baseURL}${link}`, { 
            headers: { Cookie: `railwire_cookie_name=${cookies.railwireCookie.value}; ci_session=${cookies.ciSessionCookie.value}` },
            timeout: 9000 
        });
        const $ = cheerio.load(data);
        const extract = (name) => $(`input[name=${name}]`).val()?.toLowerCase();
        return {
            firstname: extract('firstname'),
            oltabid: extract('oltabid'),
            pggroupid: extract('pggroupid'),
            pkgid: extract('pkgid'),
            anp: extract('anp'),
            vlanid: $('select#vlanid option:selected').val()?.toLowerCase(),
            caf_type: extract('caf_type'),
            mobileno: extract('mobileno')
        };
    } catch (err) { console.error(`Error extracting inputs from ${link}: ${err.message}`); return {}; }
};

const getUsername = async (firstName, baseUsername, cookies) => {
    const tryDerive = async (modUsername) => {
        try {
            const payload = new URLSearchParams({
                fname: firstName,
                lname: '',
                mod_username: modUsername,
                railwire_test_name: cookies.railwireCookie.value
            }).toString();
            const { data } = await axios.post(`${baseURL}/kycapis/derive_username`, payload, { 
                headers: { 
                    Cookie: `railwire_cookie_name=${cookies.railwireCookie.value}; ci_session=${cookies.ciSessionCookie.value}`,
                    'Content-Type': 'application/x-www-form-urlencoded'
                },
                timeout: 9000 
            });
            return data;
        } catch { return { STATUS: 'ERROR' }; }
    };

    let attempt = 0;
    let response;
    do {
        response = await tryDerive(baseUsername + (attempt || ''));
        attempt++;
    } while (response.STATUS !== 'OK' && attempt < 10);

    return response.UNAME || null;
};

const createSubscription = async (link, derivedUsername, cookies, originalMessage) => {
    try {
        const hiddenInputs = await getHiddenInputs(link, cookies);
        if (!hiddenInputs.oltabid || !hiddenInputs.pggroupid || !hiddenInputs.pkgid) {
            throw new Error('Required hidden inputs not found');
        }

        // Extract the existing username from the form
        const { data: formData } = await axios.get(`${baseURL}${link}`, { 
            headers: { Cookie: `railwire_cookie_name=${cookies.railwireCookie.value}; ci_session=${cookies.ciSessionCookie.value}` },
            timeout: 9000 
        });
        const $ = cheerio.load(formData);
        const existingUsername = ($('input#uname').attr('value') || $('input#dusername_org').attr('value') || '').trim();

        // Present options to user
        let optionsMessage = `Choose username option:\n`;
        if (existingUsername) {
            optionsMessage += `1. Default Username: ${existingUsername}\n`;
        }
        optionsMessage += `2. Bot Username: ${derivedUsername}\n`;
        optionsMessage += `3. Input Username manually\n`;
        
        await originalMessage.reply(optionsMessage);
        
        const userChoice = await waitForReply(originalMessage);
        let finalUsername;

        switch(userChoice.body.trim()) {
            case '1':
                if (existingUsername) {
                    // Verify existing username
                    const verifiedExisting = await getUsername(hiddenInputs.firstname, existingUsername, cookies);
                    if (verifiedExisting) {
                        finalUsername = existingUsername;
                    } else {
                        return false;
                    }
                }
                break;
            case '2':
                finalUsername = derivedUsername;
                break;
            case '3':
                await originalMessage.reply("Input Manual Username:");
                const manualUsernameMessage = await waitForReply(originalMessage);
                const manualUsername = manualUsernameMessage.body.trim();
                const verifiedManual = await getUsername(hiddenInputs.firstname, manualUsername, cookies);
                if (verifiedManual) {
                    finalUsername = manualUsername;
                } else {
                    return false;
                }
                break;
            default:
                await originalMessage.reply("Invalid option.");
                return false;
        }

        if (!finalUsername) return false;

        const payload = new URLSearchParams({
            oltabid: hiddenInputs.oltabid,
            uname: finalUsername,
            pggroupid: hiddenInputs.pggroupid,
            pkgid: hiddenInputs.pkgid,
            anp: hiddenInputs.anp,
            vlanid: hiddenInputs.vlanid,
            caf_type: hiddenInputs.caf_type,
            railwire_test_name: cookies.railwireCookie.value,
            mobileno: hiddenInputs.mobileno
        }).toString();

        const { status, data: subscriptionResponse } = await axios.post(`${baseURL}/kycapis/create_subscription`, payload, { 
            headers: { 
                Cookie: `railwire_cookie_name=${cookies.railwireCookie.value}; ci_session=${cookies.ciSessionCookie.value}`,
                'Content-Type': 'application/x-www-form-urlencoded'
            },
            timeout: 9000 
        });
        
        if (subscriptionResponse.STATUS === undefined) {
            throw new Error('Cookie expired during subscription creation');
        }
        
        console.log(status === 200 ? 'Subscription created.' : 'Subscription failed.', subscriptionResponse);
        
        if (status === 200) {
            const userData = await fetchUserDataFromPortal(finalUsername);
            if (userData) {
                const resetResponse = await resetPassword(userData, cookies);
                console.log('Password reset response:', resetResponse);
            } else {
                console.error('Failed to fetch user data for password reset.');
            }
        }
        return status === 200;
    } catch (err) {
        console.error(`Error creating subscription: ${err.message}`);
        return false;
    }
};


const handleVerifiedForm = async (link, cookies, originalMessage) => {
    try {
        const { data } = await axios.get(`${baseURL}${link}`, { 
            headers: { Cookie: `railwire_cookie_name=${cookies.railwireCookie.value}; ci_session=${cookies.ciSessionCookie.value}` },
            timeout: 9000 
        });
        const $ = cheerio.load(data);
        const firstName = (await getHiddenInputs(link, cookies)).firstname?.split(' ')[0]?.toLowerCase();
        if (!firstName) throw new Error('First name not found.');

        const associatedPartner = $(`.profile-info-name:contains('Associated Partner')`).next().text().trim().toLowerCase();
        const jhCode = jhCodeMap?.get(associatedPartner);
        if (!jhCode) throw new Error('JH Code not found for partner.');

        const baseUsername = `${jhCode}.${firstName}`;
        const finalUsername = await getUsername(firstName, baseUsername, cookies);
        if (!finalUsername) throw new Error('Failed to derive username.');

        return await createSubscription(link, finalUsername, cookies, originalMessage);
    } catch (err) { 
        console.error(`Error processing verified form: ${err.message}`); 
        return false;
    }
};

const handleSubmittedForm = async (link, oltabid, cookies, username, originalMessage) => {
    try {
      const { data } = await axios.get(`${baseURL}${link}`, { 
        headers: { Cookie: `railwire_cookie_name=${cookies.railwireCookie.value}; ci_session=${cookies.ciSessionCookie.value}` },
        timeout: 8000
      });
      const $ = cheerio.load(data);
  
      // Extracting Address Proof
      const addressProofElement = $(`.profile-info-name:contains('Address Proof Copy')`).next().find('span');
      const addressProof = addressProofElement.length > 0 && addressProofElement.text().trim().toLowerCase() === 'file not exists' ? 'file not exists' : 'View';
      const mobileNo = $(`.profile-info-name:contains('Mobile No.')`).next().find('span').text().trim();
  
      if (addressProof === 'file not exists') {
        console.log('Marking as verified because file not exists.');
        const payload = new URLSearchParams({ 
          oltabid, 
          mobileno_dual: mobileNo, 
          railwire_test_name: cookies.railwireCookie.value 
        }).toString();
        await axios.post(`${baseURL}/kycapis/kyc_mark_verified`, payload, { 
          headers: { 
            Cookie: `railwire_cookie_name=${cookies.railwireCookie.value}; ci_session=${cookies.ciSessionCookie.value}`,
            'Content-Type': 'application/x-www-form-urlencoded'
          },
          timeout: 5000 
        });
        return true;
      } else {
        console.log(`Address proof exists for mobile ${mobileNo}.`);

        let extractedData = `Address Proof for No.: ${mobileNo}\n\nDetails:\n`;
    
        $('.profile-info-row').each((index, element) => {
          const infoName = $(element).find('.profile-info-name').text().trim();
          const infoValueElement = $(element).find('.profile-info-value span');
  
          let infoValue = infoValueElement.text().trim();
  
          // Handle links specifically
          const linkElement = infoValueElement.find('a');
          if (linkElement.length > 0) {
            const link = linkElement.attr('href');
            infoValue = `View >> ${baseURL}${link}`;
          }
  
          if (
            !infoName.toLowerCase().includes('notice') &&
            !infoName.toLowerCase().includes('reason for kyc rejection') &&
            !infoName.toLowerCase().includes('address type') &&
            !infoName.toLowerCase().includes('id no') &&
            !infoName.toLowerCase().includes('door no') &&
            !infoName.toLowerCase().includes('street') &&
            !infoName.toLowerCase().includes('applied package')
          ) {
            extractedData += `${infoName}: ${infoValue}\n`;
          }
        });
  
        // Send the extracted data to the user
        await originalMessage.reply(extractedData);
        await originalMessage.reply(`Do you want to verify? (y/n)`);
  
        const userInputMessage = await waitForReply(originalMessage);
        const userInput = userInputMessage.body.toLowerCase();
  
        if (userInput.startsWith('y')) {
          const payload = new URLSearchParams({ 
            oltabid, 
            mobileno_dual: mobileNo, 
            railwire_test_name: cookies.railwireCookie.value 
          }).toString();
          await axios.post(`${baseURL}/kycapis/kyc_mark_verified`, payload, { 
            headers: { 
              Cookie: `railwire_cookie_name=${cookies.railwireCookie.value}; ci_session=${cookies.ciSessionCookie.value}`,
              'Content-Type': 'application/x-www-form-urlencoded'
            },
            timeout: 5000 
          });
          return true;
        } else {
          console.log('User choose not to verify. Skipping verification.');
          return false;
        }
      }
    } catch (err) { 
      console.error(`Error processing submitted form for ${username}: ${err.message}`); 
      return false;
    }
  };
 

  const handleIncomingMessage = async (message) => {

    const chat = await message.getChat();
    if (chat.isGroup && chat.name === 'Railtel & MSP team Jharkhand') {
        console.log('MSP group messages ignoring!!');
        return;
    }

    const userIdentifier = getUserIdentifier(message);
    const messageBody = message.body.toLowerCase().trim();

    console.log(`User Detail: ${userIdentifier}`);
    console.log(`Message: ${messageBody}`);

    if (messageBody.includes('activator') || messageBody.includes('origin@123')) {
        await handleReactivation(message);
        return;
    }

    if (messageBody === 'akm') {
        const cookies = await getCookies();
        if (!cookies) {
            await message.reply('Failed to authenticate. Please try again later.');
            return;
        }

        await message.reply('KYC khoj raha hun wait kijiye..');
        const totalProcessed = await processAllForms(cookies, message);
        await message.reply(`Processed + Verified: ${totalProcessed}`);
        return;
    }

    let codePattern = /jh(\.\w+){2,}/i;
    let codeMatch = messageBody.match(codePattern);
    let subscriberIdPattern = /\b\d{5}\b/;
    let subscriberIdMatch = messageBody.match(subscriberIdPattern);
    let currentUserCodeOrId = codeMatch ? codeMatch[0].toLowerCase() : (subscriberIdMatch ? subscriberIdMatch[0] : null);

    if (currentUserCodeOrId) {
        userSessions.set(userIdentifier, { userCode: currentUserCodeOrId, userData: null });
        console.log('Stored JH code or ID. Waiting for action keyword...');
    }

    const wantsSessionReset = messageBody.includes('session') || messageBody.includes('ip reset') || messageBody.includes('mac');
    const wantsPasswordReset = messageBody.includes('reset') || messageBody.includes('password') || messageBody.includes('rest') || messageBody.includes('risat') || messageBody.includes('resert');

    if ((wantsSessionReset || wantsPasswordReset) && userSessions.has(userIdentifier)) {
        await processActions(message, userIdentifier, wantsSessionReset, wantsPasswordReset);
    }
};

client.on('qr', generateQRCode);

client.on('ready', () => {
    console.log('WhatsApp Web client is ready!');
    loadExcelData();
});

client.on('message', handleIncomingMessage);

client.initialize();