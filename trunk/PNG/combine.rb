#! /usr/bin/env ruby 

require 'RMagick'
include Magick
include Math

=begin
snapshotCURVE__0_0.png
snapshotEDIT_MIX__0_0.png
snapshotCALIB_0_0.png
snapshotCURVE__1_0.png
snapshotCURVE__2_0.png
snapshotCURVE__5_0.png
snapshotEDIT_MIX__4_0.png
snapshotEXPO_DR__0_0.png
snapshotEXPO_DR___0_0.png
snapshotEXPO_DR__1_0.png
snapshotEXPO_DR__2_0.png
snapshotEXPO_DR__3_0.png
snapshotM0.png
snapshotSETUP__5_0.png
=end

MAIN=
%w(
snapshotM0-gr.png
snapshotM0-Num.png
snapshotM0-Sw.png
snapshotM0-Itr.png
)
BASE=
%w(
snapshotSETUP_BASIC1_0_0.png
snapshotSETUP_BASIC2_0_0.png
snapshotWARNINGS_0_0.png
snapshotTRAINER_0_0.png
snapshotVERSION_0_0.png
snapshotDIAG_0_0.png
snapshotANA_0_0.png
snapshotCALIB_1_0.png
)
MODELS=
%w(
snapshotMODELSEL_0_0.png
snapshotSETUP__4_0.png
snapshotEXPO_DR___3_0.png
snapshotMIXER___3_0.png
snapshotSWITCHES___6_3.png
snapshotTRIM_SUBTRIM_0_0.png
snapshotLIMITS_0_0.png
snapshotCURVES_1_0.png
)



class Main
  def initialize

    doit(MODELS,"menus-models.jpg")
    doit(BASE,"menus-base.jpg")
    doit(MAIN,"menus-main.jpg",true)
  end
  def doit(files,out,vert=false)
    if vert
      sum = Magick::Image.new(300, 250) {self.background_color='white'}
    else
      sum = Magick::Image.new(700, 150) {self.background_color='white'}
    end
    files.reverse.each_with_index{|file,i|
      img = Magick::Image.read(file).first
      # Construct a simple affine matrix
      #flipflop = Magick::AffineMatrix.new(1, Math::PI/6, Math::PI/6, 1, 0, 0)
      #                                   sx, rx, ry, sy, tx, ty
      if vert
        flipflop = Magick::AffineMatrix.new(0.8-i*0.01, -(1)*PI/180, -(15+i*1)*PI/180, 0.5+i*0.01, 0, 0)
      else
        flipflop = Magick::AffineMatrix.new(0.8, -(5-i*0.2)*PI/180, -(20+i*2)*PI/180, 0.5+i*0.01, 0, 0)
      end

      # Apply the transform
      img = img.border(1,1,'rgb(0,0,0)')
      img = img.border(1,1,'rgb(1,1,1)')
      img = img.affine_transform(flipflop)
      img = img.matte_replace(0,0)

      #i = bg.composite(img, Magick::CenterGravity, Magick::OverCompositeOp)
      #i.display

      # Create the shadow.
      img.background_color = 'black'
      shadow = img.shadow(10,10,4,0.9)
      #shadow.display
# Composite the original image over the shadow, composite the result
# onto a white background, add a border, write it to the "after" file.
      shadow = shadow.composite(img, Magick::NorthWestGravity, Magick::OverCompositeOp)
      #bg = Magick::Image.new(shadow.columns, shadow.rows) {self.background_color='white'}
      #after = bg.composite(shadow, Magick::CenterGravity, Magick::OverCompositeOp)
      #after.border!(1,1,'gray80')
      if vert
        sum = sum.composite(shadow, 20+i*10,160-i*45,Magick::OverCompositeOp)
      else
        sum = sum.composite(shadow, 430-i*60,30,Magick::OverCompositeOp)
      end

      # Scale the image, make the background transparent,
      # and write it to a JPEG file.
      #img.scale!(250.0/img.rows)
      #img.write("affine_transform.jpg")
    }
    #sum.display
    sum.write(out)
  end
end


Main.new
