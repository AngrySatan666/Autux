/*
 * img2img.java
 *
 * Compile:
 *   javac img2img.java
 *
 * Usage:
 *   java img2img <directory> [--type png|jpeg|jpg|...] [--del]
 *
 * Examples:
 *   java img2img myimages
 *   java img2img myimages --type jpeg
 *   java img2img myimages --type jpg --del
 *
 * - Converts all compatible images in <directory> (recursively) to the specified type (default: png).
 * - Outputs converted images to the 'out' directory.
 * - Logs each run and per-image results in out/skipped.txt.
 * - Use --del to delete source images after conversion.
 */

import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.List;
import javax.imageio.ImageIO;

public class img2img {
    private static final List<String> IMAGE_EXTENSIONS = Arrays.asList(
        ".jpg", ".jpeg", ".bmp", ".gif", ".tiff", ".webp", ".jfif"
    );
    private static final String OUT_DIR = "out";
    private static final String LOG_FILE = "skipped.txt";

    public static void main(String[] args) {
        if (args.length < 1) {
            System.out.println("Usage: java img2img <directory> [--type png|jpeg|jpg|...] [--del]");
            return;
        }
        String directory = args[0];
        String outType = "png";
        boolean deleteSource = false;
        for (int i = 1; i < args.length; i++) {
            if (args[i].equals("--type") && i + 1 < args.length) {
                outType = args[i + 1].toLowerCase();
                i++;
            } else if (args[i].equals("--del")) {
                deleteSource = true;
            }
        }
        convertImages(directory, OUT_DIR, outType, deleteSource);
    }

    private static void convertImages(String directory, String outputDir, String outType, boolean deleteSource) {
        List<String> compatible = new ArrayList<>();
        List<String> nonCompatible = new ArrayList<>();
        getCompatibleImages(directory, compatible, nonCompatible);
        int total = compatible.size();
        File outDir = new File(outputDir);
        if (!outDir.exists()) outDir.mkdirs();
        File logFile = new File(outDir, LOG_FILE);
        String now = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date());
        try {
            Files.write(logFile.toPath(), ("\n--- Run at " + now + " ---\n").getBytes(), Files.exists(logFile.toPath()) ? java.nio.file.StandardOpenOption.APPEND : java.nio.file.StandardOpenOption.CREATE);
            Files.write(logFile.toPath(), ("Directory: " + directory + "\n").getBytes(), java.nio.file.StandardOpenOption.APPEND);
            Files.write(logFile.toPath(), ("Output type: " + outType + "\n").getBytes(), java.nio.file.StandardOpenOption.APPEND);
            Files.write(logFile.toPath(), ("Delete source: " + deleteSource + "\n").getBytes(), java.nio.file.StandardOpenOption.APPEND);
            Files.write(logFile.toPath(), ("Found " + total + " compatible images.\n").getBytes(), java.nio.file.StandardOpenOption.APPEND);
            if (!nonCompatible.isEmpty()) {
                Files.write(logFile.toPath(), "Non-compatible files:\n".getBytes(), java.nio.file.StandardOpenOption.APPEND);
                for (String item : nonCompatible) {
                    Files.write(logFile.toPath(), ("  " + item + "\n").getBytes(), java.nio.file.StandardOpenOption.APPEND);
                }
            } else {
                Files.write(logFile.toPath(), "No non-compatible files.\n".getBytes(), java.nio.file.StandardOpenOption.APPEND);
            }
        } catch (IOException e) {
            System.out.println("Failed to write log: " + e.getMessage());
        }
        if (total == 0) {
            System.out.println("No compatible images found.");
            System.out.println("Non-compatible files: " + nonCompatible);
            System.out.println("Run log written to: " + logFile.getAbsolutePath());
            return;
        }
        System.out.println("Found " + total + " compatible images.");
        if (!nonCompatible.isEmpty()) {
            System.out.println("Non-compatible files:");
            for (String item : nonCompatible) {
                System.out.println("  " + item);
            }
            System.out.println("Run log written to: " + logFile.getAbsolutePath());
        }
        int idx = 1;
        for (String imgPath : compatible) {
            String baseName = new File(imgPath).getName();
            int dot = baseName.lastIndexOf('.');
            if (dot > 0) baseName = baseName.substring(0, dot);
            String outExt = outType.equals("jpg") ? ".jpeg" : "." + outType;
            String outFile = outputDir + File.separator + baseName + outExt;
            String saveType = outType.equals("jpg") ? "jpeg" : outType;
            try {
                BufferedImage img = ImageIO.read(new File(imgPath));
                if (img == null) throw new IOException("Not a supported image file");
                ImageIO.write(img, saveType, new File(outFile));
                appendLog(logFile, "SUCCESS: " + imgPath + " -> " + outFile);
                if (deleteSource) {
                    try {
                        Files.delete(Paths.get(imgPath));
                        appendLog(logFile, "DELETED: " + imgPath);
                    } catch (IOException delE) {
                        appendLog(logFile, "FAILED TO DELETE: " + imgPath + " | " + delE.getMessage());
                    }
                }
            } catch (Exception e) {
                appendLog(logFile, "FAILED: " + imgPath + " | " + e.getMessage());
                System.out.println("Failed to convert " + imgPath + ": " + e.getMessage());
            }
            printProgress(idx++, total, imgPath);
        }
        System.out.println("Conversion complete.");
    }

    private static void getCompatibleImages(String directory, List<String> compatible, List<String> nonCompatible) {
        File dir = new File(directory);
        if (!dir.exists() || !dir.isDirectory()) return;
        for (File file : dir.listFiles()) {
            if (file.isDirectory()) {
                getCompatibleImages(file.getAbsolutePath(), compatible, nonCompatible);
            } else {
                String ext = getFileExtension(file.getName());
                if (IMAGE_EXTENSIONS.contains(ext)) {
                    compatible.add(file.getAbsolutePath());
                } else {
                    nonCompatible.add(file.getAbsolutePath());
                }
            }
        }
    }

    private static String getFileExtension(String filename) {
        int dot = filename.lastIndexOf('.');
        return dot >= 0 ? filename.substring(dot).toLowerCase() : "";
    }

    private static void appendLog(File logFile, String line) {
        try {
            Files.write(logFile.toPath(), (line + "\n").getBytes(), java.nio.file.StandardOpenOption.APPEND);
        } catch (IOException e) {
            System.out.println("Failed to write log: " + e.getMessage());
        }
    }

    private static void printProgress(int current, int total, String filename) {
        int barLength = 40;
        double percent = (double) current / total;
        int filled = (int) (percent * barLength);
        String bar = "[" + "-".repeat(Math.max(0, filled - 1)) + (filled > 0 ? ">" : "") + " ".repeat(barLength - filled) + "] ";
        System.out.print("\r" + bar + current + "/" + total + "  " + new File(filename).getName());
        if (current == total) System.out.println();
    }
}
