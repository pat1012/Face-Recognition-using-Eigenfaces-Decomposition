clear all;
close all;
clc;
N=1; % number of people in training set
M=100; % number of images in training set.
%H=100;
%W=75;
%L=7500; % L=H*W
e=zeros(N*M,1);
mindist=0;
mintemp=0;
person=0;

%Chosen std and mean. 
%It can be any number that it is close to the std and mean of most of the images.
um=100;
ustd=80;

%********************************************************************************************
disp('begin');
for j=1:N
    %read and show images(bmp);
    S=[];   %img matrix
    for i=1:M
        % read in image to img
        str=strcat(int2str(10*(j-1)+i),'.bmp');   %concatenates two strings that form the name of the image
        eval('img=imread(str);');  
        img = rgb2gray(img); %img is 3d, I have to change it into 2D inorder to do processing
        %*****************************
        %histogram equalization
        img = histeq(img);
        %*****************************
        % Normallzation
        %Min = min(min(img));
        %Max = max(max(img));
        %img = (img - Min)*255/(Max-Min);
        %****************************
        [irow icol]=size(img);    % get the number of rows (N1) and columns (N2)
        temp=reshape(img',irow*icol,1);     %creates a (N1*N2)x1 matrix, for one training image
        S=[S temp];         %S is a N1*N2xM matrix after finishing the sequence                       
    end

    %Here we change the mean and std of all images. We normalize all images.
    %This is done to reduce the error due to lighting conditions.
    
    for i=1:size(S,2)
        temp=double(S(:,i));
        m=mean(temp);
        st=std(temp);
        S(:,i)=(temp-m)*ustd/st+um;
    end
    
    %mean image;
    m=mean(S,2);   %obtains the mean of each row instead of each column
    %tmimg=uint8(m);   %converts to unsigned 8-bit integer. Values range from 0 to 255
    tmimg=m;
    img=reshape(tmimg,icol,irow);    %takes the N1*N2x1 vector and creates a N2xN1 matrix
    img=img';       %creates a N1xN2 matrix by transposing the image.
    %figure;
    %imshow(img);
    img=reshape(img,icol*irow,1);
    % store mean image, img
    eval(strcat('img',int2str(j),'=m;'));

    % Change image for manipulation
    dbx=[];   % A matrix
    for i=1:M
        temp=double(S(:,i));
        dbx=[dbx temp];
    end

    %Covariance matrix C=A'A, L=AA'
    A=dbx';
    L=A*A';
    % vv are the eigenvector for L
    % dd are the eigenvalue for both L=dbx'*dbx and C=dbx*dbx';
    [vv dd]=eig(L);
    % Sort and eliminate those whose eigenvalue is zero
    v=[];
    d=[];
    for i=1:size(vv,2)
        if(dd(i,i)>1e-4)
            v=[v vv(:,i)];
            d=[d dd(i,i)];
        end
     end

     %sort,  will return an ascending sequence
     [B index]=sort(d);
     ind=zeros(size(index));
     dtemp=zeros(size(index));
     vtemp=zeros(size(v));
     len=length(index);
     for i=1:len
        dtemp(i)=B(len+1-i);
        ind(i)=len+1-index(i);
        vtemp(:,ind(i))=v(:,i);
     end
     d=dtemp;
     v=vtemp;

    %Normalization of eigenvectors
     for i=1:size(v,2)       %access each column
       kk=v(:,i);
       temp=sqrt(sum(kk.^2));
       v(:,i)=v(:,i)./temp;
    end

    %Eigenvectors of C matrix
    u=[];
    for i=1:size(v,2)
        temp=sqrt(d(i));
        u=[u (dbx*v(:,i))./temp];
    end

    %Normalization of eigenvectors
    for i=1:size(u,2)
       kk=u(:,i);
       temp=sqrt(sum(kk.^2));
        u(:,i)=u(:,i)./temp;
    end

    % Find the weight of each face in the training set.
    omega = [];
    for h=1:size(dbx,2)
        WW=[];    
        for i=1:size(u,2)
            t = u(:,i)';    
            WeightOfImage = dot(t,dbx(:,h)');
            WW = [WW; WeightOfImage];
        end
        omega = [omega WW];
    end

    % store u,omega for one person
    eval(strcat('u',int2str(j),'=u;'));
    eval(strcat('omega',int2str(j),'=omega;'));
    
end % end for loop, done with one person's data
    
%********************************************************************************
while 1    
    %Read data from the new imgage
    prompt = 'Please type the name of the photo? ';
    str = input(prompt,'s'); 
    InputImage = imread(strcat(str,'.bmp'));
    InputImage = rgb2gray(InputImage);
    % Histogram Equaliztion
    InputImage = histeq(InputImage);
    
    %*****************************
    % Normallzation
    %Min = min(min(InputImage));
    %Max = max(max(InputImage));
    %InputImage = (InputImage - Min)*255/(Max-Min);
    %****************************
    
    [irow icol] = size(InputImage); % Get the size of the image
    InImage=reshape(double(InputImage)',irow*icol,1);  
    temp=InImage;
    me=mean(temp);
    st=std(temp);
    temp=(temp-me)*ustd/st+um; % temp is the normalized input image
    NormImage = temp;
    
    for j=1:N
        eval(strcat('Difference = temp - img',int2str(j),';'));   % Difference=temp-img(j)    
        InImWeight = [];
        for i=1:M    % i=1:size(u1,2)
            eval(strcat('t=u',int2str(j),'(:,i);')); %t=u1(:,1)
            t=t'; %t = u1(:,i)'
            WeightOfInputImage = dot(t,Difference');
            InImWeight = [InImWeight; WeightOfInputImage];
        end

        for i=1:M %i=1:size(omega1,2)
            eval(strcat('q=omega',int2str(j),'(:,i);')); %q = omega1(:,i);
            DiffWeight = InImWeight-q;
            mag = norm(DiffWeight);
            e ((j-1)*M+i)=mag;
        end
    end %end for loop
    
    % show min and person
    maxe = max(e);
    mindist=min(e);
    mintemp=e(1);
    person=1;
    for k=1:N*M
        if mintemp>e(k)
            mintemp=e(k);
            person=k;
        end
    end
    %mintemp
    person
    %{
    if mintemp>28000
        display('The input person is not in the library.');
    %person=ceil(person/M)
    else
        mindist
        person
    end
    %}
end % end while loop
% We may have to increase the data base










