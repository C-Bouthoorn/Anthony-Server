package imagePainter;

import java.awt.Color;
import java.awt.image.BufferedImage;
import java.io.File;

import javax.imageio.ImageIO;


public class ImagePainter {
	public ImagePainter(String[] args) {
		if ( args.length < 1 ) {
			System.out.println("No filename specified");
			return;
		}
		
		if ( args.length < 2 ) {
			System.out.println("No color specified");
			return;
		}
		
		File file = new File(args[0]);
		
		String color = args[1];
		
		// Convert #ffffff to 255,255,255 
		int r = Integer.parseInt(color.substring(1,3), 16),
			g = Integer.parseInt(color.substring(3,5), 16),
			b = Integer.parseInt(color.substring(5,7), 16);
			
		Color newColor = new Color(r, g, b);
		
		String filename = file.getName();
		int lastdot = filename.lastIndexOf('.');
		String base = filename.substring(0, lastdot);
		String ext = filename.substring(lastdot+1);
		
		String newFilename = file.getAbsoluteFile().getParent() + "/converted/" + base + "-" + Integer.toHexString(newColor.getRGB() & 0xffffff) + "." + ext;
		File newFile = new File(newFilename);
		
		System.out.println(newFilename);
		
		if ( newFile.exists() ) {
			System.out.println("Already exists!");
			return;
		}
		
		
		BufferedImage image;
		
		try {
			System.out.println("Reading file");
			image = ImageIO.read(file);
			
			System.out.println("Converting colours");
			for(int x=0; x < image.getWidth(); ++x) {
				for(int y=0; y < image.getHeight(); ++y ) {
					Color c = new Color(image.getRGB(x, y), true);
					
					r = c.getRed(); g = c.getGreen(); b = c.getBlue();
					
					if ( r > 127 && g < r && b < r ) {  // That's kinda red'ish, right?
						
						// Convert color to match newColor
						r = (int) Math.round( r/255.0 * newColor.getRed()   );
						g = (int) Math.round( g/255.0 * newColor.getGreen() );
						b = (int) Math.round( b/255.0 * newColor.getBlue()  );
						
						c = new Color(r, g, b, newColor.getAlpha());
					}
					
					image.setRGB(x, y, c.getRGB());
				}
			}
			
			System.out.println("Writing file");
			
			ImageIO.write(image, ext, newFile);
		} catch(Exception e) {
			e.printStackTrace(System.err);
		}
		
		System.out.println("Done");
	}
	
	
	public static ImagePainter imagePainter;
	public static void main(String[] args) {
		imagePainter = new ImagePainter(args);
	}
}
