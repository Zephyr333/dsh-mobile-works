package android.graphics;
import java.io.OutputStream;
public class Bitmap {
    public enum CompressFormat { JPEG, PNG }
    public Bitmap() {}
    public boolean compress(CompressFormat format, int quality, OutputStream stream) { return false; }
    public void recycle() {}
}
