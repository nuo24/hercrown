"""Preserve the approved screenshot artwork and replace only the phone display.
The six original PNGs are immutable layout templates. Native captures are CUA
Device Hub screenshots. No Scripture or native UI text is recreated here.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'design/app-store-screenshots'
DEST = BASE / 'build33/decorated-white'
DEST.mkdir(parents=True, exist_ok=True)
# Foreground illustrations cross the phone's edge. Keep their original pixels.
# Coordinates below are in the template's 300 px-wide inspection grid.
items = [
 ('01-read-scripture','01-reader', [ [(14,303),(27,295),(37,298),(48,306),(51,318),(46,328),(53,336),(48,343),(46,352),(39,346),(38,333),(27,334),(20,326)], [(240,519),(253,526),(267,537),(284,533),(295,540),(288,551),(281,559),(279,570),(270,576),(261,570),(250,570),(243,560)] ]),
 ('02-discover','02-discover', [[(15,280),(24,271),(31,276),(35,287),(41,316),(27,323),(21,311)]]),
 ('03-study','03-study', [[(12,387),(25,384),(34,389),(39,401),(35,412),(46,424),(52,430),(48,435),(38,430),(29,417),(19,413),(12,406)],[(230,541),(250,532),(264,533),(273,542),(282,548),(290,560),(275,565),(258,572),(246,568),(239,557)]]),
 ('04-daily-reading','04-home', [[(13,353),(30,345),(36,355),(34,369),(41,384),(32,391),(21,387),(19,375)]]),
 ('05-saved-passages','05-saved', [[(22,325),(29,324),(33,330),(32,342),(38,350),(45,354),(42,366),(33,357),(27,353),(26,341)]]),
 ('06-dark-mode','06-dark', [[(7,321),(17,313),(28,310),(42,312),(51,324),(46,333),(48,339),(37,348),(22,348),(13,341)],[(232,541),(245,545),(255,558),(264,565),(273,562),(289,558),(294,565),(287,576),(277,583),(268,590),(257,590),(246,584),(241,573)]]),
]
for old,new,polygons in items:
 template=Image.open(BASE/(old+'.png')).convert('RGB')
 canvas=template.copy() # Original white backdrop, captions, frame and decorations.
 native=Image.open(BASE/'build33/native'/(new+'.png')).convert('RGB')
 box=(158,652,1048,2582)
 native=native.resize((box[2]-box[0],box[3]-box[1]),Image.Resampling.LANCZOS)
 mask=Image.new('L',native.size,0)
 ImageDraw.Draw(mask).rounded_rectangle((0,0,native.width-1,native.height-1),radius=96,fill=255)
 canvas.paste(native,box[:2],mask)
 # Reuse the original Dynamic Island silhouette, without changing app content.
 ImageDraw.Draw(canvas).rounded_rectangle((499,681,708,738),radius=29,fill='#060909')
 front=Image.new('L',canvas.size,0);d=ImageDraw.Draw(front)
 for polygon in polygons:d.polygon([(round(x*4.02),round(y*4.02)) for x,y in polygon],fill=255)
 front=front.filter(ImageFilter.GaussianBlur(.6));canvas.paste(template,(0,0),front)
 canvas.save(DEST/(old+'.png'),optimize=True)
contact=Image.new('RGB',(1800,670),'white')
for i,(old,_,_) in enumerate(items):
 image=Image.open(DEST/(old+'.png'));image.thumbnail((300,650));contact.paste(image,(300*i,10))
contact.save(DEST/'preview.jpg',quality=92)
