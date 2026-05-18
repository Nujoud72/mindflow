# 🧠 MindFlow — Bilişsel Gelişim için Kural Tabanlı Mobil Zihin Egzersizi Uygulaması

MindFlow, 7–12 yaş arası çocuklara yönelik geliştirilen, kural tabanlı adaptif zorluk yapısına sahip bir mobil bilişsel egzersiz uygulamasıdır.

Bu proje, Isparta Uygulamalı Bilimler Üniversitesi Bilgisayar Mühendisliği Bölümü bitirme tezi kapsamında geliştirilmektedir.

> ⚠️ Bu proje geliştirme aşamasındadır. Özellikler ve sistem yapısı proje ilerledikçe güncellenecektir.

## 👥 Proje Bilgileri

**Danışman:** Prof. Dr. Tuncay Aydoğan  
**Takım Üyeleri:** Shams AL HAJJI & Nujoud Alkhatib  

## 📌 Projenin Amacı

Projenin amacı, 7–12 yaş arası çocukların dikkat, hafıza ve problem çözme gibi bilişsel becerilerini destekleyen mobil bir zihin egzersizi sistemi geliştirmektir.

Sistem; başarı oranı, tepki süresi ve hata sayısı gibi performans verilerini kullanarak oyun zorluk seviyesini IF–THEN kurallarıyla dinamik olarak ayarlamayı hedeflemektedir.

## 🎯 Temel Hedefler

- En az 5 farklı bilişsel oyun modülü geliştirmek
- Dikkat, hafıza ve problem çözme becerilerini desteklemek
- Başarı oranı, tepki süresi ve hata sayısına dayalı adaptif zorluk algoritması tasarlamak
- Kullanıcı performans verilerini kayıt altına almak
- Firestore üzerinde kullanıcı ilerleme verilerini saklamak
- Ön test – son test yaklaşımıyla sistemi değerlendirmek

## 🛠️ Kullanılan Teknolojiler

| Katman | Teknoloji |
|---|---|
| Mobil Uygulama | Flutter |
| Kimlik Doğrulama | Firebase Authentication |
| Veritabanı | Firebase Cloud Firestore |
| Backend / Servisler | Python tabanlı servisler |
| Hedef Platform | Android |

## ⚙️ Sistem Nasıl Çalışır?

1. Kullanıcı Firebase Authentication ile giriş yapar.
2. Kullanıcı oyun kategorisi seçer.
3. Oyun oynanırken performans verileri toplanır.
4. Sistem başarı oranı, hata sayısı ve tepki süresini analiz eder.
5. IF–THEN kuralları ile zorluk seviyesi belirlenir.
6. Sonuçlar Firestore veritabanına kaydedilir.
7. Kullanıcıya skorlar ve grafiklerle geri bildirim sunulur.

## 🔁 Adaptif Zorluk Mantığı

Örnek kural yapısı:

```text
IF başarı oranı yüksek AND hata sayısı düşük THEN zorluk artırılır.
IF başarı oranı düşük OR hata sayısı yüksek THEN zorluk azaltılır.
IF başarı oranı yeterli AND tepki süresi normal THEN mevcut seviye korunur.
```

## 🚧 Geliştirme Durumu

Proje şu anda aktif geliştirme aşamasındadır. Oyun modülleri, kullanıcı performans takibi ve adaptif zorluk sistemi proje sürecinde geliştirilmeye devam etmektedir.

## 📱 Hedef Platform

MindFlow, Android mobil cihazlar için geliştirilmektedir.

## 📂 Proje Durumu

Bu depo, MindFlow bitirme projesinin kaynak kodlarını ve geliştirme sürecine ait dosyaları içermektedir. Proje tamamlandıkça README dosyası güncellenecektir.
