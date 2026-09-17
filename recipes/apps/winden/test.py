import time
import sys
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service

options = Options()
options.add_argument("--headless=new")
options.add_argument("--no-sandbox")
options.add_argument("--disable-dev-shm-usage")
options.add_argument("--disable-gpu")
options.add_argument("--remote-debugging-pipe")
options.binary_location = "@chromium@/bin/chromium"
options.set_capability("goog:loggingPrefs", {"browser": "ALL"})

service = Service(executable_path="@chromedriver@/bin/chromedriver")
driver = webdriver.Chrome(service=service, options=options)

try:
    print("Loading http://localhost:8080 in Headless Chromium...")
    driver.get("http://localhost:8080")
    time.sleep(3)

    print("Creating test file to upload...")
    with open("/tmp/test_upload.txt", "w") as f:
        f.write("Hello from Winden E2E test!")

    print("Uploading test file to input[type='file']...")
    file_input = driver.find_element("css selector", "input[type='file']")
    file_input.send_keys("/tmp/test_upload.txt")

    print("Waiting for Wormhole code generation...")
    time.sleep(8)

    logs = driver.get_log("browser")
    errors = []
    for log in logs:
        print("BROWSER LOG:", log)
        if log["level"] == "SEVERE":
            # Ignore favicon 404 and React 18 render deprecation warning
            msg = log.get("message", "")
            if (
                "favicon" not in msg
                and "ReactDOM.render is no longer supported" not in msg
            ):
                errors.append(msg)

    if errors:
        print("SEVERE browser console errors detected:", errors)
        sys.exit(1)

    body = driver.find_element("tag name", "body").text
    print("Page body after upload:\n", body[:400])
    if not body.strip():
        print("ERROR: Winden UI rendered empty body!")
        sys.exit(1)

    print("Winden UI loaded and uploaded file successfully.")
finally:
    driver.quit()
