import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { App } from '@/App';
import { MessageDetail } from '@/components/message-viewer/message-detail';
import { NotFound } from '@/components/not-found';

export function AppRoutes() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<App />} />
        <Route path="/message/:id" element={<MessageDetail />} />
        <Route path="/404" element={<NotFound />} />
        <Route path="*" element={<Navigate to="/404" replace />} />
      </Routes>
    </BrowserRouter>
  );
}
