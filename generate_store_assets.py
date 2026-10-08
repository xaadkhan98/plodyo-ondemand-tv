import os
import shutil
from PIL import Image, ImageDraw, ImageFilter
import numpy as np

# Ensure target directories exist
store_assets_dir = '/Users/muhammadshoaib/StudioProjects/plodyo-ondemand-tv/assets/store_assets'
os.makedirs(store_assets_dir, exist_ok=True)
artifact_dir = '/Users/muhammadshoaib/.gemini/antigravity-ide/brain/a27ef425-f3ef-47e2-87e3-556b02fb083c'

img1_path = os.path.join(artifact_dir, '.user_uploaded/media_1789622753473.png')
img2_path = os.path.join(artifact_dir, '.user_uploaded/media_1789622753498.png')
img3_path = os.path.join(artifact_dir, '.user_uploaded/media_1789622753530.png')

def create_gradient_bg(width, height, top_color, bottom_color):
    """Creates a smooth vertical linear gradient image."""
    top_r, top_g, top_b = [float(x) for x in top_color[:3]]
    bot_r, bot_g, bot_b = [float(x) for x in bottom_color[:3]]
    arr = np.zeros((height, width, 4), dtype=np.uint8)
    for y in range(height):
        t = y / max(height - 1, 1)
        arr[y, :, 0] = int(np.clip(top_r + (bot_r - top_r) * t, 0, 255))
        arr[y, :, 1] = int(np.clip(top_g + (bot_g - top_g) * t, 0, 255))
        arr[y, :, 2] = int(np.clip(bot_b + (bot_b - top_b) * t, 0, 255))
        arr[y, :, 3] = 255
    return Image.fromarray(arr)

def clean_corner_artifacts(im):
    arr = np.array(im)
    if arr[-1, 0, 0] < 200:
        for r in range(arr.shape[0]-8, arr.shape[0]):
            for c in range(8):
                if arr[r, c, 0] < 200:
                    arr[r, c] = arr[r, 9]
    return Image.fromarray(arr)

# -------------------------------------------------------------------------
# 1. SCREENSHOT 1: Sign in to the TV (with keyboard) - 1920x1080 (16:9)
# -------------------------------------------------------------------------
def create_screenshot_1():
    im1 = Image.open(img1_path).convert('RGBA')
    im1 = clean_corner_artifacts(im1)
    w, h = im1.size
    
    scale = 1920 / w
    new_w = 1920
    new_h = int(round(h * scale))
    resized = im1.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    top_color = (250, 245, 255, 255)
    bottom_color = (253, 242, 248, 255)
    canvas = create_gradient_bg(1920, 1080, top_color, bottom_color)
    
    y_offset = (1080 - new_h) // 2
    if y_offset > 0:
        top_row = resized.crop((0, 0, new_w, 1))
        top_ext = top_row.resize((new_w, y_offset), Image.Resampling.NEAREST)
        canvas.paste(top_ext, (0, 0))
        
        bot_gap = 1080 - (y_offset + new_h)
        if bot_gap > 0:
            bot_row = resized.crop((0, new_h-1, new_w, new_h))
            bot_ext = bot_row.resize((new_w, bot_gap), Image.Resampling.NEAREST)
            canvas.paste(bot_ext, (0, y_offset + new_h))
            
    canvas.paste(resized, (0, y_offset), resized)
    return canvas

# -------------------------------------------------------------------------
# 2. SCREENSHOT 2: Super Admin Console - 1920x1080 (16:9)
# -------------------------------------------------------------------------
def create_screenshot_2():
    im2 = Image.open(img2_path).convert('RGBA')
    im2 = clean_corner_artifacts(im2)
    w, h = im2.size
    
    scale = 1920 / w
    new_w = 1920
    new_h = int(round(h * scale))
    resized = im2.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    top_color = (252, 249, 255, 255)
    bottom_color = (253, 242, 248, 255)
    canvas = create_gradient_bg(1920, 1080, top_color, bottom_color)
    
    rail_w = int(round(42 * scale))
    draw_c = ImageDraw.Draw(canvas)
    draw_c.rectangle([0, 0, rail_w, 1080], fill=(252, 249, 255, 255))
    draw_c.line([(rail_w, 0), (rail_w, 1080)], fill=(234, 227, 241, 255), width=1)
    
    y_offset = (1080 - new_h) // 2
    if y_offset > 0:
        top_row = resized.crop((rail_w + 1, 0, new_w, 1))
        top_ext = top_row.resize((new_w - (rail_w + 1), y_offset), Image.Resampling.NEAREST)
        canvas.paste(top_ext, (rail_w + 1, 0))
        
        bot_gap = 1080 - (y_offset + new_h)
        if bot_gap > 0:
            bot_row = resized.crop((rail_w + 1, new_h-1, new_w, new_h))
            bot_ext = bot_row.resize((new_w - (rail_w + 1), bot_gap), Image.Resampling.NEAREST)
            canvas.paste(bot_ext, (rail_w + 1, y_offset + new_h))
            
    canvas.paste(resized, (0, y_offset), resized)
    return canvas

# -------------------------------------------------------------------------
# 3. SCREENSHOT 3: Partners Management - 1920x1080 (16:9)
# -------------------------------------------------------------------------
def create_screenshot_3():
    im3 = Image.open(img3_path).convert('RGBA')
    im3_clean = im3.crop((0, 0, im3.width, 488))
    im3_clean = clean_corner_artifacts(im3_clean)
    
    scale = 1920 / im3_clean.width
    new_w = 1920
    new_h = int(round(im3_clean.height * scale))
    resized = im3_clean.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    top_color = (252, 249, 255, 255)
    bottom_color = (253, 242, 248, 255)
    canvas = create_gradient_bg(1920, 1080, top_color, bottom_color)
    
    rail_w = int(round(42 * scale))
    draw_c = ImageDraw.Draw(canvas)
    draw_c.rectangle([0, 0, rail_w, 1080], fill=(252, 249, 255, 255))
    draw_c.line([(rail_w, 0), (rail_w, 1080)], fill=(234, 227, 241, 255), width=1)
    
    y_offset = (1080 - new_h) // 2
    if y_offset > 0:
        top_row = resized.crop((rail_w + 1, 0, new_w, 1))
        top_ext = top_row.resize((new_w - (rail_w + 1), y_offset), Image.Resampling.NEAREST)
        canvas.paste(top_ext, (rail_w + 1, 0))
        
        bot_gap = 1080 - (y_offset + new_h)
        if bot_gap > 0:
            bot_row = resized.crop((rail_w + 1, new_h-1, new_w, new_h))
            bot_ext = bot_row.resize((new_w - (rail_w + 1), bot_gap), Image.Resampling.NEAREST)
            canvas.paste(bot_ext, (rail_w + 1, y_offset + new_h))
            
    canvas.paste(resized, (0, y_offset), resized)
    return canvas

# -------------------------------------------------------------------------
# 4. TV BANNER (1,280 px by 720 px)
# -------------------------------------------------------------------------
def create_tv_banner():
    banner_source = os.path.join(artifact_dir, 'tv_banner_ambient_1789623487832.jpg')
    im_banner = Image.open(banner_source).convert('RGB')
    banner_1280 = im_banner.resize((1280, 720), Image.Resampling.LANCZOS)
    return banner_1280

print("Generating screenshots...")
sc1 = create_screenshot_1()
sc2 = create_screenshot_2()
sc3 = create_screenshot_3()
banner = create_tv_banner()

# Save PNGs (lossless, optimized, under 8 MB)
sc1.convert('RGB').save(os.path.join(store_assets_dir, 'tv_screenshot_1_signin.png'), format='PNG', optimize=True)
sc2.convert('RGB').save(os.path.join(store_assets_dir, 'tv_screenshot_2_console.png'), format='PNG', optimize=True)
sc3.convert('RGB').save(os.path.join(store_assets_dir, 'tv_screenshot_3_partners.png'), format='PNG', optimize=True)
banner.save(os.path.join(store_assets_dir, 'tv_banner_1280x720.png'), format='PNG', optimize=True)

# Save JPEGs (quality 95%, under 8 MB)
sc1.convert('RGB').save(os.path.join(store_assets_dir, 'tv_screenshot_1_signin.jpg'), format='JPEG', quality=95)
sc2.convert('RGB').save(os.path.join(store_assets_dir, 'tv_screenshot_2_console.jpg'), format='JPEG', quality=95)
sc3.convert('RGB').save(os.path.join(store_assets_dir, 'tv_screenshot_3_partners.jpg'), format='JPEG', quality=95)
banner.save(os.path.join(store_assets_dir, 'tv_banner_1280x720.jpg'), format='JPEG', quality=95)

# Also save copies into artifact directory
shutil.copy(os.path.join(store_assets_dir, 'tv_screenshot_1_signin.png'), os.path.join(artifact_dir, 'tv_screenshot_1_signin.png'))
shutil.copy(os.path.join(store_assets_dir, 'tv_screenshot_2_console.png'), os.path.join(artifact_dir, 'tv_screenshot_2_console.png'))
shutil.copy(os.path.join(store_assets_dir, 'tv_screenshot_3_partners.png'), os.path.join(artifact_dir, 'tv_screenshot_3_partners.png'))
shutil.copy(os.path.join(store_assets_dir, 'tv_banner_1280x720.png'), os.path.join(artifact_dir, 'tv_banner_1280x720.png'))

print("All Android TV Screenshots (1920x1080) and TV Banner (1280x720) regenerated successfully.")
