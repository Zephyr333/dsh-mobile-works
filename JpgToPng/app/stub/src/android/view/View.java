package android.view;
public class View {
    public static final int VISIBLE = 0;
    public static final int INVISIBLE = 4;
    public static final int GONE = 8;
    public View() {}
    public interface OnClickListener { void onClick(View v); }
    public void setOnClickListener(OnClickListener l) {}
    public void setEnabled(boolean enabled) {}
    public void setPadding(int left, int top, int right, int bottom) {}
}
