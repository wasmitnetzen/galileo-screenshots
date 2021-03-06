from django.utils.crypto import get_random_string
from os import path

from celery import shared_task
from .models import Screenshot
from selenium import webdriver
from selenium.webdriver.chrome.options import Options

from django.conf import settings
from django.utils import timezone


@shared_task
def take_screenshot(screenshot_pk):
    screenshot = Screenshot.objects.get(pk=screenshot_pk)
    url = screenshot.url
    # call Selenium webdriver

    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-setuid-sandbox")
    chrome_options.add_argument("--disable-gpu")

    driver = webdriver.Chrome('chromedriver', chrome_options=chrome_options)
    driver.get(url)
    # generate random file name
    random_filename = get_random_string(length=64)
    driver.save_screenshot(path.join(settings.MEDIA_ROOT, random_filename))

    screenshot.screenshot_name = random_filename
    screenshot.screenshot_time = timezone.now()
    screenshot.user_agent = driver.execute_script("return navigator.userAgent;")
    screenshot.save()

    driver.quit()
