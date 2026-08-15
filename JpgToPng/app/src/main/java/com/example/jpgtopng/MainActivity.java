package com.example.jpgtopng;

import android.app.Activity;
import android.content.ContentResolver;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

public class MainActivity extends Activity {
    private static final int REQ_PICK = 1;
    private static final int REQ_SAVE = 2;

    private Bitmap bitmap;
    private TextView status;
    private Button saveButton;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setPadding(40, 40, 40, 40);

        TextView title = new TextView(this);
        title.setText("JPG 转 PNG");
        title.setTextSize(24);
        layout.addView(title);

        Button pickButton = new Button(this);
        pickButton.setText("选择 JPG/JPEG 图片");
        layout.addView(pickButton);

        status = new TextView(this);
        status.setText("请选择一张 JPG 图片");
        layout.addView(status);

        saveButton = new Button(this);
        saveButton.setText("保存 PNG");
        saveButton.setEnabled(false);
        layout.addView(saveButton);

        pickButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                chooseJpg();
            }
        });

        saveButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                savePng();
            }
        });

        setContentView(layout);
    }

    private void chooseJpg() {
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.setType("image/jpeg");
        startActivityForResult(intent, REQ_PICK);
    }

    private void savePng() {
        if (bitmap == null) return;
        Intent intent = new Intent(Intent.ACTION_CREATE_DOCUMENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.setType("image/png");
        intent.putExtra(Intent.EXTRA_TITLE, "JpgToPng_" + System.currentTimeMillis() + ".png");
        startActivityForResult(intent, REQ_SAVE);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (resultCode != RESULT_OK || data == null || data.getData() == null) return;
        Uri uri = data.getData();
        if (requestCode == REQ_PICK) {
            loadAndConvert(uri);
        } else if (requestCode == REQ_SAVE) {
            writePng(uri);
        }
    }

    private void loadAndConvert(Uri uri) {
        ContentResolver resolver = getContentResolver();
        try (InputStream in = resolver.openInputStream(uri)) {
            if (in == null) {
                toast("无法打开该图片");
                return;
            }
            Bitmap loaded = BitmapFactory.decodeStream(in);
            if (loaded == null) {
                toast("无法解码该图片");
                return;
            }
            if (bitmap != null) {
                bitmap.recycle();
            }
            bitmap = loaded;
            status.setText("转换成功，可保存 PNG");
            saveButton.setEnabled(true);
        } catch (IOException e) {
            toast("读取图片失败");
        } catch (SecurityException e) {
            toast("没有权限读取该图片");
        }
    }

    private void writePng(Uri uri) {
        if (bitmap == null) return;
        ContentResolver resolver = getContentResolver();
        try (OutputStream out = resolver.openOutputStream(uri)) {
            if (out == null) {
                toast("无法写入文件");
                return;
            }
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out);
            toast("已保存 PNG");
        } catch (IOException e) {
            toast("保存失败");
        } catch (SecurityException e) {
            toast("没有权限保存文件");
        }
    }

    private void toast(String msg) {
        Toast.makeText(this, msg, Toast.LENGTH_SHORT).show();
    }
}
