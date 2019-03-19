namespace HFO_ENGINE
{
    partial class Montage
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.Montage_title = new System.Windows.Forms.Label();
            this.SuggestedMontageLabel = new System.Windows.Forms.Label();
            this.ComboBox_suggested_montage = new System.Windows.Forms.ComboBox();
            this.ComboBox_bipolar_montage = new System.Windows.Forms.ComboBox();
            this.BipolarMontageLabel = new System.Windows.Forms.Label();
            this.Montage_save_btn = new System.Windows.Forms.Button();
            this.panel2 = new System.Windows.Forms.Panel();
            this.panel2.SuspendLayout();
            this.SuspendLayout();
            // 
            // Montage_title
            // 
            this.Montage_title.Font = new System.Drawing.Font("Arial", 18F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.Montage_title.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.Montage_title.Location = new System.Drawing.Point(45, 55);
            this.Montage_title.Name = "Montage_title";
            this.Montage_title.Size = new System.Drawing.Size(189, 40);
            this.Montage_title.TabIndex = 0;
            this.Montage_title.Text = "Montage setup";
            // 
            // SuggestedMontageLabel
            // 
            this.SuggestedMontageLabel.BackColor = System.Drawing.Color.Transparent;
            this.SuggestedMontageLabel.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.SuggestedMontageLabel.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.SuggestedMontageLabel.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.SuggestedMontageLabel.Location = new System.Drawing.Point(0, 0);
            this.SuggestedMontageLabel.Name = "SuggestedMontageLabel";
            this.SuggestedMontageLabel.Size = new System.Drawing.Size(197, 50);
            this.SuggestedMontageLabel.TabIndex = 2;
            this.SuggestedMontageLabel.Text = "Suggested Montage";
            // 
            // ComboBox_suggested_montage
            // 
            this.ComboBox_suggested_montage.FormattingEnabled = true;
            this.ComboBox_suggested_montage.Location = new System.Drawing.Point(10, 50);
            this.ComboBox_suggested_montage.Name = "ComboBox_suggested_montage";
            this.ComboBox_suggested_montage.Size = new System.Drawing.Size(316, 21);
            this.ComboBox_suggested_montage.TabIndex = 3;
            // 
            // ComboBox_bipolar_montage
            // 
            this.ComboBox_bipolar_montage.FormattingEnabled = true;
            this.ComboBox_bipolar_montage.Location = new System.Drawing.Point(10, 153);
            this.ComboBox_bipolar_montage.Name = "ComboBox_bipolar_montage";
            this.ComboBox_bipolar_montage.Size = new System.Drawing.Size(316, 21);
            this.ComboBox_bipolar_montage.TabIndex = 5;
            // 
            // BipolarMontageLabel
            // 
            this.BipolarMontageLabel.BackColor = System.Drawing.Color.Transparent;
            this.BipolarMontageLabel.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.BipolarMontageLabel.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.BipolarMontageLabel.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.BipolarMontageLabel.Location = new System.Drawing.Point(0, 100);
            this.BipolarMontageLabel.Name = "BipolarMontageLabel";
            this.BipolarMontageLabel.Size = new System.Drawing.Size(140, 50);
            this.BipolarMontageLabel.TabIndex = 4;
            this.BipolarMontageLabel.Text = "Bipolar Montage";
            // 
            // Montage_save_btn
            // 
            this.Montage_save_btn.BackgroundImageLayout = System.Windows.Forms.ImageLayout.None;
            this.Montage_save_btn.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.Montage_save_btn.Font = new System.Drawing.Font("Microsoft Sans Serif", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.Montage_save_btn.ForeColor = System.Drawing.SystemColors.ControlLightLight;
            this.Montage_save_btn.Location = new System.Drawing.Point(275, 215);
            this.Montage_save_btn.Name = "Montage_save_btn";
            this.Montage_save_btn.Size = new System.Drawing.Size(82, 34);
            this.Montage_save_btn.TabIndex = 6;
            this.Montage_save_btn.Text = "Save";
            this.Montage_save_btn.UseVisualStyleBackColor = true;
            this.Montage_save_btn.Click += new System.EventHandler(this.Montage_save_btn_Click);
            // 
            // panel2
            // 
            this.panel2.Controls.Add(this.Montage_save_btn);
            this.panel2.Controls.Add(this.BipolarMontageLabel);
            this.panel2.Controls.Add(this.ComboBox_bipolar_montage);
            this.panel2.Controls.Add(this.SuggestedMontageLabel);
            this.panel2.Controls.Add(this.ComboBox_suggested_montage);
            this.panel2.Location = new System.Drawing.Point(55, 120);
            this.panel2.Name = "panel2";
            this.panel2.Size = new System.Drawing.Size(360, 250);
            this.panel2.TabIndex = 10;
            // 
            // Montage
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(49)))), ((int)(((byte)(66)))), ((int)(((byte)(82)))));
            this.ClientSize = new System.Drawing.Size(480, 512);
            this.Controls.Add(this.Montage_title);
            this.Controls.Add(this.panel2);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.None;
            this.Name = "Montage";
            this.Text = "Montage";
            this.panel2.ResumeLayout(false);
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.Label Montage_title;
        private System.Windows.Forms.Label SuggestedMontageLabel;
        private System.Windows.Forms.ComboBox ComboBox_suggested_montage;
        private System.Windows.Forms.ComboBox ComboBox_bipolar_montage;
        private System.Windows.Forms.Label BipolarMontageLabel;
        private System.Windows.Forms.Button Montage_save_btn;
        private System.Windows.Forms.Panel panel2;
    }
}