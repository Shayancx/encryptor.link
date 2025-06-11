import React from 'react';
import { QRCode } from 'react-qrcode-logo';
import { Button } from '@/components/ui/button';
import { Download } from 'lucide-react';

interface QRGeneratorProps {
  value: string;
  size?: number;
  bgColor?: string;
  fgColor?: string;
}

export function QRGenerator({ value, size = 200, bgColor = "#FFFFFF", fgColor = "#000000" }: QRGeneratorProps) {
  const downloadQRCode = () => {
    const canvas = document.getElementById('qr-code-canvas') as HTMLCanvasElement;
    if (!canvas) return;
    
    const link = document.createElement('a');
    link.download = 'encrypted-message-qr.png';
    link.href = canvas.toDataURL('image/png');
    link.click();
  };

  return (
    <div className="flex flex-col items-center gap-4">
      <QRCode
        id="qr-code-canvas"
        value={value}
        size={size}
        bgColor={bgColor}
        fgColor={fgColor}
        qrStyle="dots"
        eyeRadius={5}
        removeQrCodeBehindLogo={true}
      />
      <Button size="sm" onClick={downloadQRCode} className="flex items-center gap-2">
        <Download className="w-4 h-4" />
        Download QR Code
      </Button>
    </div>
  );
}
